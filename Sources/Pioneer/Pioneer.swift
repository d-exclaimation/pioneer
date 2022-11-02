//
//  Pioneer.swift
//  GraphQLAsyncSequence
//
//  Created by d-exclaimation on 12:18 AM.
//

import NIO
import Foundation
import class GraphQL.GraphQLSchema
import struct GraphQL.GraphQLResult
import struct GraphQL.GraphQLError
import enum GraphQL.OperationType

/// Pioneer GraphQL Server for handling all GraphQL operations
public struct Pioneer<Resolver, Context> {
    /// Graphiti schema used to execute operations
    public private(set) var schema: GraphQLSchema
    /// Resolver used by the GraphQL schema
    public private(set) var resolver: Resolver
    /// HTTP strategy
    public private(set) var httpStrategy: HTTPStrategy
    /// Websocket sub-protocol
    public private(set) var websocketProtocol: WebsocketProtocol
    /// Allowing introspection
    public private(set) var introspection: Bool
    /// Allowing GraphQL IDE
    public private(set) var playground: IDE
    /// Validation rules 
    public private(set) var validationRules: Validations
    /// Keep alive period
    public private(set) var keepAlive: UInt64?
    /// Timeout period
    public private(set) var timeout: UInt64?

    /// Internal running WebSocket actor for Pioneer
    internal var probe: Probe

    /// - Parameters:
    ///   - schema: GraphQL schema used to execute operations
    ///   - resolver: Resolver used by the GraphQL schema
    ///   - contextBuilder: Context builder from request
    ///   - httpStrategy: HTTP strategy
    ///   - websocketContextBuilder: Context builder for the websocket
    ///   - websocketOnInit: Function to intercept websocket connection during the initialization phase
    ///   - websocketProtocol: Websocket sub-protocol
    ///   - introspection: Allowing introspection
    ///   - playground: Allowing playground
    ///   - validationRules: Validation rules to be applied before operation
    ///   - keepAlive: Keep alive interval in nanosecond, default to 12.5 sec, nil for disable
    ///   - timeout: Timeout interval in nanosecond, default to 5 sec, nil for disable
    public init(
        schema: GraphQLSchema,
        resolver: Resolver,
        httpStrategy: HTTPStrategy = .csrfPrevention,
        websocketProtocol: WebsocketProtocol = .graphqlWs,
        introspection: Bool = true,
        playground: IDE = .sandbox,
        validationRules: Validations = .none,
        keepAlive: UInt64? = .seconds(30),
        timeout: UInt64? = .seconds(5)
    ) {
        self.schema = schema
        self.resolver = resolver
        self.httpStrategy = httpStrategy
        self.websocketProtocol = websocketProtocol
        self.introspection = introspection
        self.playground = !introspection ? .disable : playground
        self.validationRules = validationRules
        self.keepAlive = keepAlive
        self.timeout = timeout


        let proto: SubProtocol.Type = def {
            switch websocketProtocol {
            case .graphqlWs:
                return GraphQLWs.self
            default:
                return SubscriptionTransportWs.self
            }
        }

        let probe = Probe(
            schema: schema,
            resolver: resolver,
            proto: proto
        )
        self.probe = probe
    }

    /// Guard for operation allowed
    internal func allowed(from gql: GraphQLRequest, allowing: [OperationType] = [.query, .mutation, .subscription]) -> Bool {
        guard introspection || !gql.isIntrospection else {
            return false
        }
        guard let operationType = gql.operationType else {
            return false
        }
        return allowing.contains(operationType)
    }

    /// Execute operation through Pioneer for a GraphQLRequest, context and get a well formatted GraphQlResult
    /// - Parameters:
    ///   - gql: The GraphQL Request for this operation
    ///   - ctx: The context for the operation
    ///   - eventLoop: The event loop used to execute the operation asynchronously
    /// - Returns: A well-formatted GraphQLResult
    public func executeOperation(for gql: GraphQLRequest, with ctx: Context, using eventLoop: EventLoopGroup) async -> GraphQLResult {
        do {
            return try await executeGraphQL(
                schema: schema,
                request: gql.query,
                resolver: resolver,
                context: ctx,
                eventLoopGroup: eventLoop,
                variables: gql.variables,
                operationName: gql.operationName
            )
        } catch {
            return GraphQLResult(data: nil, errors: [error.graphql])
        }
    }


    /// Handle messages that follow the websocket protocol for a specific client using Pioneer.Probe 
    /// - Parameters:
    ///   - pid: The client key
    ///   - io: The client IO
    ///   - keepAlive: The keepAlive interval for the client
    ///   - timeout: The timeout interval for the client
    ///   - ev: Any event loop
    ///   - txt: The message received
    ///   - context: The context builder for the client
    public func receiveMessage(
        pid: UUID, 
        io: WebSocketable,
        keepAlive: Task<Void, Error>?,
        timeout: Task<Void, Error>?, 
        ev: EventLoopGroup,
        txt: String,
        context: @escaping WebSocketContext,
        check: @escaping WebSocketGuard
    ) async  {
        guard let data = txt.data(using: .utf8) else {
            // Shouldn't accept any message that aren't utf8 string
            // -> Close with 1003 code
            try? await io.terminate(code: .unacceptableData)
            return
        }

        switch websocketProtocol.parse(data) {

        // Initial sub-protocol handshake established
        // Dispatch process to probe so it can start accepting operations
        // Timer fired here to keep connection alive by sub-protocol standard
        case .initial(let payload):
            do {
                try await check(payload)
                await initialiseClient(
                    pid: pid, 
                    io: io, 
                    payload: payload, 
                    timeout: timeout, 
                    ev: ev,
                    context: context
                )
            } catch {
                let err = GraphQLMessage.errors(type: websocketProtocol.error, [error.graphql])
                io.out(err.jsonString)

                // Deallocation of resources
                await probe.disconnect(for: pid)
                keepAlive?.cancel()
                try? await io.terminate(code: .graphqlInvalid) 
            }

        // Ping is for requesting server to send a keep alive message
        case .ping:
            io.out(GraphQLMessage(type: websocketProtocol.pong).jsonString)

        // Explicit message to terminate connection to deallocate resources, stop timer, and close connection
        case .terminate:
            await probe.disconnect(for: pid)
            keepAlive?.cancel()
            timeout?.cancel()
            try? await io.terminate(code: .normalClosure)

        // Start -> Long running operation
        case .start(oid: let oid, gql: let gql):
            await executeLongOperation(pid: pid, io: io, oid: oid, gql: gql)

        // Once -> Short lived operation
        case .once(oid: let oid, gql: let gql):
            await executeShortOperation(pid: pid, io: io, oid: oid, gql: gql)

        // Stop -> End any running operation
        case .stop(oid: let oid):
            await probe.stop(
                for: pid,
                with: oid
            )

        // Error in validation should notify that no operation will be run, does not close connection
        case .error(oid: let oid, message: let message):
            let err = GraphQLMessage.errors(id: oid, type: websocketProtocol.error, [.init(message: message)])
            io.out(err.jsonString)

        // Fatal error is an event trigger when message given in unacceptable by protocol standard
        // This message if processed any further will cause securities vulnerabilities, thus connection should be closed
        case .fatal(message: let message):
            let err = GraphQLMessage.errors(type: websocketProtocol.error, [.init(message: message)])
            io.out(err.jsonString)

            // Deallocation of resources
            await probe.disconnect(for: pid)
            keepAlive?.cancel()
            try? await io.terminate(code: .graphqlInvalid)

        case .ignore:
            break
        }
    }

    /// Initialise a client and connect it to Pioneer.Probe
    /// - Parameters:
    ///   - pid: The client key
    ///   - io: The client IO
    ///   - payload: The initial connectionpayload 
    ///   - timeout: The timeout interval for the client
    ///   - ev: Any event loop
    ///   - context: The context builder for the client
    public func initialiseClient(
        pid: UUID, 
        io: WebSocketable, 
        payload: Payload, 
        timeout: Task<Void, Error>?, 
        ev: EventLoopGroup,
        context: @escaping WebSocketContext
    ) async {
        let client = WebSocketClient(id: pid, io: io, payload: payload, ev: ev, context: context)
        await probe.connect(with: client)
        websocketProtocol.initialize(io)
        timeout?.cancel()
    }

    /// Close a client connected through Pioneer.Probe
    /// - Parameters:
    ///   - pid: The client key
    ///   - keepAlive: The client's keepAlive interval
    ///   - timeout: The client's timeout interval
    public func closeClient(pid: UUID, keepAlive: Task<Void, Error>?, timeout: Task<Void, Error>?) {
        Task {
            await probe.disconnect(for: pid)
        }
        keepAlive?.cancel()
        timeout?.cancel()
    }

    /// Execute long-lived operation through Pioneer.Probe for a GraphQLRequest, context and get a well formatted GraphQlResult 
    /// - Parameters:
    ///   - pid: The client key
    ///   - io: The client IO for outputting errors
    ///   - oid: The key for this operation
    ///   - gql: The GraphQL Request for this operation
    public func executeLongOperation(pid: UUID, io: WebSocketable, oid: String, gql: GraphQLRequest) async {
        // Introspection guard
        guard allowed(from: gql) else {
            let err = GraphQLMessage.errors(id: oid, type: websocketProtocol.error, [
                .init(message: "GraphQL introspection is not allowed by Pioneer, but the query contained __schema or __type.")
            ])
            return io.out(err.jsonString)
        }
        let errors = validationRules(using: schema, for: gql)
        guard errors.isEmpty else {
            let err = GraphQLMessage.errors(id: oid, type: websocketProtocol.error, errors)
            return io.out(err.jsonString)
        }

        await probe.start(
            for: pid,
            with: oid,
            given: gql
        )
    }

    /// Execute short-lived operation through Pioneer.Probe for a GraphQLRequest, context and get a well formatted GraphQlResult 
    /// - Parameters:
    ///   - pid: The client key
    ///   - io: The client IO for outputting errors
    ///   - oid: The key for this operation
    ///   - gql: The GraphQL Request for this operation
    public func executeShortOperation(pid: UUID, io: WebSocketable, oid: String, gql: GraphQLRequest) async {
        // Introspection guard
        guard allowed(from: gql) else {
            let err = GraphQLMessage.errors(id: oid, type: websocketProtocol.error, [
                .init(message: "GraphQL introspection is not allowed by Pioneer, but the query contained __schema or __type.")
            ])
            return io.out(err.jsonString)
        }
        let errors = validationRules(using: schema, for: gql)
        guard errors.isEmpty else {
            let err = GraphQLMessage.errors(id: oid, type: websocketProtocol.error, errors)
            return io.out(err.jsonString)
        }

        await probe.once(
            for: pid,
            with: oid,
            given: gql
        )
    }
}
