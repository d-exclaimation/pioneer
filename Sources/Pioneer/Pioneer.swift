//
//  Pioneer.swift
//  GraphQLAsyncSequence
//
//  Created by d-exclaimation on 12:18 AM.
//  Copyright © 2021 d-exclaimation. All rights reserved.
//

import Vapor
import Desolate
import GraphQL

/// Pioneer GraphQL Vapor Server for handling all GraphQL operations
public struct Pioneer<Resolver, Context> {
    /// Graphiti schema used to execute operations
    public var schema: GraphQLSchema
    /// Resolver used by the GraphQL schema
    public var resolver: Resolver
    /// Context builder from request
    public var contextBuilder: (Request, Response) -> Context
    /// HTTP strategy
    public var httpStrategy: HTTPStrategy
    /// Websocket sub-protocol
    public var websocketProtocol: WebsocketProtocol
    /// Allowing introspection
    public var introspection: Bool

    /// Internal running desolated actor for Pioneer
    internal var probe: Desolate<Probe>

    /// - Parameters:
    ///   - schema: GraphQL schema used to execute operations
    ///   - resolver: Resolver used by the GraphQL schema
    ///   - contextBuilder: Context builder from request
    ///   - httpStrategy: HTTP strategy
    ///   - websocketProtocol: Websocket sub-protocol
    ///   - introspection: Allowing introspection
    public init(
        schema: GraphQLSchema,
        resolver: Resolver,
        contextBuilder: @escaping (Request, Response) -> Context,
        httpStrategy: HTTPStrategy = .queryOnlyGet,
        websocketProtocol: WebsocketProtocol = .subscriptionsTransportWs,
        introspection: Bool = true
    ) {
        self.schema = schema
        self.resolver = resolver
        self.contextBuilder = contextBuilder
        self.httpStrategy = httpStrategy
        self.websocketProtocol = websocketProtocol
        self.introspection = introspection

        let proto: SubProtocol.Type = returns {
            switch websocketProtocol {
            case .graphqlWs:
                return GraphQLWs.self
            default:
                return SubscriptionTransportWs.self
            }
        }

        let probe = Desolate(of: Probe(
            schema: schema,
            resolver: resolver,
            proto: proto
        ))
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
        let result = try await executeGraphQL(
            schema: schema,
            request: gql.query,
            resolver: resolver,
            context: contextBuilder(req, res),
            eventLoopGroup: req.eventLoop,
            variables: gql.variables,
            operationName: gql.operationName
        )
        try res.content.encode(result)
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
