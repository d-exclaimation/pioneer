//
//  Pioneer.swift
//  GraphQLAsyncSequence
//
//  Created by d-exclaimation on 12:18 AM.
//

import Vapor
import class GraphQL.GraphQLSchema
import struct GraphQL.GraphQLResult
import struct GraphQL.GraphQLError
import enum GraphQL.OperationType

/// Pioneer GraphQL Vapor Server for handling all GraphQL operations
public struct Pioneer<Resolver, Context> {
    /// Graphiti schema used to execute operations
    public private(set) var schema: GraphQLSchema
    /// Resolver used by the GraphQL schema
    public private(set) var resolver: Resolver
    /// Context builder from request
    public private(set) var contextBuilder: @Sendable (Request, Response) async throws -> Context
    /// HTTP strategy
    public private(set) var httpStrategy: HTTPStrategy
    /// Websocket Context builder
    public private(set) var websocketContextBuilder: @Sendable (Request, Payload, GraphQLRequest) async throws -> Context
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
        contextBuilder: @Sendable @escaping (Request, Response) async throws -> Context,
        httpStrategy: HTTPStrategy = .queryOnlyGet,
        websocketContextBuilder: @Sendable @escaping (Request, Payload, GraphQLRequest) async throws -> Context,
        websocketOnInit: @Sendable @escaping (Payload) async throws -> Void = { _ in },
        websocketProtocol: WebsocketProtocol = .graphqlWs,
        introspection: Bool = true,
        playground: IDE = .sandbox,
        validationRules: Validations = .none,
        keepAlive: UInt64? = .seconds(30),
        timeout: UInt64? = .seconds(5)
    ) {
        self.schema = schema
        self.resolver = resolver
        self.contextBuilder = contextBuilder
        self.httpStrategy = httpStrategy
        self.websocketContextBuilder = websocketContextBuilder
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
            proto: proto,
            websocketContextBuilder: websocketContextBuilder
        )
        self.probe = probe
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
}
