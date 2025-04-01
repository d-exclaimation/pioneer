//
//  Pioneer.swift
//  GraphQLAsyncSequence
//
//  Created by d-exclaimation on 12:18 AM.
//

import Foundation
import struct GraphQL.GraphQLError
import struct GraphQL.GraphQLResult
import class GraphQL.GraphQLSchema
import enum GraphQL.OperationType
import NIO

/// Pioneer GraphQL Server for handling all GraphQL operations
public struct Pioneer<Resolver: Sendable, Context: Sendable>: Sendable {
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
        self.probe = .init(
            schema: schema,
            resolver: resolver,
            proto: expression {
                switch websocketProtocol {
                case .subscriptionsTransportWs:
                    return SubscriptionTransportWs.self
                default:
                    return GraphQLWs.self
                }
            }
        )
    }

    /// Guard for operation allowed
    /// - Parameters:
    ///   - gql: GraphQL operation
    ///   - allowing: Set of operation allowed
    /// - Returns: True if operation should be allowed
    public func allowed(from gql: GraphQLRequest, allowing: [OperationType] = [.query, .mutation, .subscription]) -> Bool {
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

    /// Execute operation through Pioneer for a HTTPGraphQLRequest and return an HTTPGraphQLResponse
    /// - Parameters:
    ///   - req: The HTTP GraphQL Request for this operation
    ///   - context: The context for the operation
    ///   - eventLoop: The event loop used to execute the operation asynchronously
    /// - Returns: A HTTPGraphQLResponse
    public func executeHTTPGraphQLRequest(for req: HTTPGraphQLRequest, with context: Context, using eventLoop: EventLoopGroup) async -> HTTPGraphQLResponse {
        let gql = req.request
        let headers = req.headers

        // CSRF and XS-Search attacks prevention
        guard !csrfVulnerable(given: headers) else {
            let error = GraphQLError(message: "Operation has been blocked as a potential Cross-Site Request Forgery (CSRF).")
            return .init(result: .init(data: nil, errors: [error]), status: .badRequest)
        }

        // HTTP Strategy checks
        guard allowed(from: gql, allowing: httpStrategy.allowed(for: req.method)) else {
            let error = GraphQLError(message: "Operation of this type is not allowed and has been blocked")
            return .init(result: .init(data: nil, errors: [error]), status: .badRequest)
        }

        // Validation rules
        let errors = validationRules(using: schema, for: gql)
        guard errors.isEmpty else {
            return .init(result: .init(data: nil, errors: errors), status: .badRequest)
        }
        let result = await executeOperation(for: gql, with: context, using: eventLoop)
        return .init(
            result: result,
            status: .ok,
            headers: req.isAcceptingGraphQLResponse ? ["Content-Type": HTTPGraphQLRequest.contentType] : nil
        )
    }

    /// Handle messages that follow the websocket protocol for a specific client using Pioneer.Probe
    /// - Parameters:
    ///   - cid: The client key
    ///   - io: The client IO
    ///   - keepAlive: The keepAlive interval for the client
    ///   - timeout: The timeout interval for the client
    ///   - ev: Any event loop
    ///   - txt: The message received
    ///   - context: The context builder for the client
    public func receiveMessage(
        cid: UUID,
        io: WebSocketable,
        keepAlive: Task<Void, Error>?,
        timeout: Task<Void, Error>?,
        ev: EventLoopGroup,
        txt: String,
        context: @escaping WebSocketContext,
        check: @escaping WebSocketGuard
    ) async {
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
        case let .initial(payload):
            do {
                try await check(payload)
                await createClient(
                    cid: cid,
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
                await probe.disconnect(for: cid)
                keepAlive?.cancel()
                try? await io.terminate(code: .graphqlInvalid)
            }

        // Ping is for requesting server to send a keep alive message
        case .ping:
            io.out(GraphQLMessage(type: websocketProtocol.pong).jsonString)

        // Explicit message to terminate connection to deallocate resources, stop timer, and close connection
        case .terminate:
            await probe.disconnect(for: cid)
            keepAlive?.cancel()
            timeout?.cancel()
            try? await io.terminate(code: .normalClosure)

        // Start -> Long running operation
        case let .start(oid: oid, gql: gql):
            await executeLongOperation(cid: cid, io: io, oid: oid, gql: gql)

        // Once -> Short lived operation
        case let .once(oid: oid, gql: gql):
            await executeShortOperation(cid: cid, io: io, oid: oid, gql: gql)

        // Stop -> End any running operation
        case let .stop(oid: oid):
            await probe.stop(
                for: cid,
                with: oid
            )

        // Error in validation should notify that no operation will be run, does not close connection
        case let .error(oid: oid, message: message):
            let err = GraphQLMessage.errors(id: oid, type: websocketProtocol.error, [.init(message: message)])
            io.out(err.jsonString)

        // Fatal error is an event trigger when message given in unacceptable by protocol standard
        // This message if processed any further will cause securities vulnerabilities, thus connection should be closed
        case let .fatal(message: message):
            let err = GraphQLMessage.errors(type: websocketProtocol.error, [.init(message: message)])
            io.out(err.jsonString)

            // Deallocation of resources
            await probe.disconnect(for: cid)
            keepAlive?.cancel()
            try? await io.terminate(code: .graphqlInvalid)

        case .ignore:
            break
        }
    }

    /// Initialise a client and connect it to Pioneer.Probe
    /// - Parameters:
    ///   - cid: The client key
    ///   - io: The client IO
    ///   - payload: The initial connectionpayload
    ///   - timeout: The timeout interval for the client
    ///   - ev: Any event loop
    ///   - context: The context builder for the client
    @discardableResult
    public func createClient(
        cid: WebSocketClient.ID,
        io: WebSocketable,
        payload: Payload,
        timeout: Task<Void, Error>?,
        ev: EventLoopGroup,
        context: @escaping WebSocketContext
    ) async -> WebSocketClient {
        let client = WebSocketClient(id: cid, io: io, payload: payload, ev: ev, context: context)
        await probe.connect(with: client)
        websocketProtocol.initialize(io)
        timeout?.cancel()
        return client
    }

    /// Close a client connected through Pioneer.Probe
    /// - Parameters:
    ///   - cid: The client key
    ///   - keepAlive: The client's keepAlive interval
    ///   - timeout: The client's timeout interval
    public func disposeClient(cid: WebSocketClient.ID, keepAlive: Task<Void, Error>?, timeout: Task<Void, Error>?) {
        Task {
            await probe.disconnect(for: cid)
        }
        keepAlive?.cancel()
        timeout?.cancel()
    }

    /// Execute subscription through Pioneer.Probe for a GraphQLRequest, context and get a well formatted GraphQlResult
    /// - Parameters:
    ///   - cid: The client key
    ///   - io: The client IO for outputting errors
    ///   - oid: The key for this operation
    ///   - gql: The GraphQL Request for this operation
    public func executeLongOperation(cid: WebSocketClient.ID, io: WebSocketable, oid: String, gql: GraphQLRequest) async {
        // Introspection guard
        guard allowed(from: gql) else {
            let err = GraphQLMessage.errors(id: oid, type: websocketProtocol.error, [
                .init(message: "GraphQL introspection is not allowed by Pioneer, but the query contained __schema or __type."),
            ])
            return io.out(err.jsonString)
        }
        let errors = validationRules(using: schema, for: gql)
        guard errors.isEmpty else {
            let err = GraphQLMessage.errors(id: oid, type: websocketProtocol.error, errors)
            return io.out(err.jsonString)
        }

        await probe.start(
            for: cid,
            with: oid,
            given: gql
        )
    }

    /// Execute short-lived operation through Pioneer.Probe for a GraphQLRequest, context and get a well formatted GraphQlResult
    /// - Parameters:
    ///   - cid: The client key
    ///   - io: The client IO for outputting errors
    ///   - oid: The key for this operation
    ///   - gql: The GraphQL Request for this operation
    public func executeShortOperation(cid: WebSocketClient.ID, io: WebSocketable, oid: String, gql: GraphQLRequest) async {
        // Introspection guard
        guard allowed(from: gql) else {
            let err = GraphQLMessage.errors(id: oid, type: websocketProtocol.error, [
                .init(message: "GraphQL introspection is not allowed by Pioneer, but the query contained __schema or __type."),
            ])
            return io.out(err.jsonString)
        }
        let errors = validationRules(using: schema, for: gql)
        guard errors.isEmpty else {
            let err = GraphQLMessage.errors(id: oid, type: websocketProtocol.error, errors)
            return io.out(err.jsonString)
        }

        // Execute operation at actor level to not block or exhaust the event loop
        await probe.once(
            for: cid,
            with: oid,
            given: gql
        )
    }
}
