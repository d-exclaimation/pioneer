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
    public var httpStrategy: HTTPStrategy = .queryOnlyGet
    public var wsProtocol: WebsocketProtocol = .subscriptionsTransportWs

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
        if wsProtocol.isAccepting {
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

    internal func allowed(from gql: GraphQLRequest, allowing: [OperationType]) throws -> Bool {
        guard let operationType = try gql.operationType() else {
            return false
        }
        return allowing.contains(operationType)
    }
}