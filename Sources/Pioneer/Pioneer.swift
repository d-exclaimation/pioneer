//
//  Pioneer.swift
//  GraphQLAsyncSequence
//
//  Created by d-exclaimation on 12:18 AM.
//  Copyright © 2021 d-exclaimation. All rights reserved.
//

import Vapor
import Graphiti
import GraphQL

public struct Pioneer<Resolver, Context> {
    public var schema: Schema<Resolver, Context>
    public var resolver: Resolver
    public var contextBuilder: (Request) -> Context
    public var httpStrategy: HTTPStrategy
    public var websocketProtocol: WebsocketProtocol
    public var introspection: Bool

    var probe: Desolate<Probe>

    public init(
        schema: Schema<Resolver, Context>,
        resolver: Resolver,
        contextBuilder: @escaping (Request) -> Context,
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

    internal func handle(req: Request, from gql: GraphQLRequest, allowing: [OperationType]) async throws -> Response {
        guard try allowed(from: gql, allowing: allowing) else {
            throw GraphQLError(ResolveError.unableToParseQuery)
        }
        let result = try await schema
            .execute(
                request: gql.query,
                resolver: resolver,
                context: contextBuilder(req),
                eventLoopGroup: req.eventLoop,
                variables: gql.variables ?? [:],
                operationName: gql.operationName
            )
            .get()
        return try await result.encodeResponse(for: req)
    }

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