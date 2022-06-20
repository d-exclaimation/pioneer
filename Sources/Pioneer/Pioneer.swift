//
//  Pioneer.swift
//  GraphQLAsyncSequence
//
//  Created by d-exclaimation on 12:18 AM.
//

import Vapor
import GraphQL

/// Pioneer GraphQL Vapor Server for handling all GraphQL operations
public struct Pioneer<Resolver, Context> {
    /// Graphiti schema used to execute operations
    public var schema: GraphQLSchema
    /// Resolver used by the GraphQL schema
    public var resolver: Resolver
    /// Context builder from request
    public var contextBuilder: @Sendable (Request, Response) async throws -> Context
    /// HTTP strategy
    public var httpStrategy: HTTPStrategy
    /// Websocket Context builder
    public var websocketContextBuilder: @Sendable (Request, ConnectionParams, GraphQLRequest) async throws -> Context
    /// Websocket sub-protocol
    public var websocketProtocol: WebsocketProtocol
    /// Allowing introspection
    public var introspection: Bool
    /// Allowing GraphQL IDE
    public var playground: IDE
    /// Keep alive period
    public var keepAlive: UInt64?

    /// Internal running WebSocket actor for Pioneer
    internal var probe: Probe

    /// - Parameters:
    ///   - schema: GraphQL schema used to execute operations
    ///   - resolver: Resolver used by the GraphQL schema
    ///   - contextBuilder: Context builder from request
    ///   - httpStrategy: HTTP strategy
    ///   - websocketContextBuilder: Context builder for the websocket
    ///   - websocketProtocol: Websocket sub-protocol
    ///   - introspection: Allowing introspection
    ///   - playground: Allowing playground
    ///   - keepAlive: Keep alive internal in nanosecond, default to 12.5 sec, nil for disable
    public init(
        schema: GraphQLSchema,
        resolver: Resolver,
        contextBuilder: @escaping @Sendable (Request, Response) async throws -> Context,
        httpStrategy: HTTPStrategy = .queryOnlyGet,
        websocketContextBuilder: @escaping @Sendable (Request, ConnectionParams, GraphQLRequest) async throws -> Context,
        websocketProtocol: WebsocketProtocol = .graphqlWs,
        introspection: Bool = true,
        playground: IDE = .graphiql,
        keepAlive: UInt64? = 12_500_000_000
    ) {
        self.schema = schema
        self.resolver = resolver
        self.contextBuilder = contextBuilder
        self.httpStrategy = httpStrategy
        self.websocketContextBuilder = websocketContextBuilder
        self.websocketProtocol = websocketProtocol
        self.introspection = introspection
        self.playground = !introspection ? .disable : playground
        self.keepAlive = keepAlive


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

    /// Apply Pioneer GraphQL handlers to a Vapor route
    public func applyMiddleware(on router: RoutesBuilder, at path: PathComponent = "graphql") {
        // HTTP Portion
        switch httpStrategy {
        case .onlyPost:
            applyPost(on: router, at: path, allowing: [.query, .mutation])

        case .onlyGet:
            applyGet(on: router, at: path, allowing: [.query, .mutation])

        case .queryOnlyGet:
            applyGet(on: router, at: path, allowing: [.query])
            applyPost(on: router, at: path, allowing: [.query, .mutation])

        case .mutationOnlyPost:
            applyGet(on: router, at: path, allowing: [.query, .mutation])
            applyPost(on: router, at: path, allowing: [.mutation])

        case .splitQueryAndMutation:
            applyGet(on: router, at: path, allowing: [.query])
            applyPost(on: router, at: path, allowing: [.mutation])

        case .both:
            applyGet(on: router, at: path, allowing: [.query, .mutation])
            applyPost(on: router, at: path, allowing: [.query, .mutation])
        }
        
        switch playground {
        case .playground:
            applyPlayground(on: router, at: path)
        case .graphiql:
            applyGraphiQL(on: router, at: path)
        case .sandbox:
            applyEmbeddedSandbox(on: router, at: path)
        case .redirect(to: .apolloSandbox):
            applySandboxRedirect(on: router, with: "https://studio.apollographql.com/sandbox/explorer")
        case .redirect(to: .bananaCakePop):
            applySandboxRedirect(on: router, with: "https://eat.bananacakepop.com")
        case .disable:
            break
        }
        
        // Websocket portion
        if websocketProtocol.isAccepting {
            applyWebSocket(on: router, at: [path, "websocket"])
        }
    }

    enum ResolveError: Error {
        case unableToParseQuery
        case unsupportedProtocol
    }

    /// Handle execution for GraphQL operation
    internal func handle(req: Request, from gql: GraphQLRequest, allowing: [OperationType]) async throws -> Response {
        guard try allowed(from: gql, allowing: allowing) else {
            throw GraphQLError(ResolveError.unableToParseQuery)
        }
        let res = Response()
        do {
            let context = try await contextBuilder(req, res)
            let result = try await executeGraphQL(
                schema: schema,
                request: gql.query,
                resolver: resolver,
                context: context,
                eventLoopGroup: req.eventLoop,
                variables: gql.variables,
                operationName: gql.operationName
            )
            try res.content.encode(result)
        } catch {
            try res.content.encode(GraphQLResult(data: nil, errors: [
                error as? GraphQLError ?? GraphQLError(error)
            ]))
        }
        return res
    }

    /// Guard for operation allowed
    internal func allowed(from gql: GraphQLRequest, allowing: [OperationType] = [.query, .mutation, .subscription]) throws -> Bool {
        guard introspection || !gql.isIntrospection else {
            return false
        }
        guard let operationType = try gql.operationType() else {
            return false
        }
        return allowing.contains(operationType)
    }
}
