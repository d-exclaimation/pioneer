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

    public enum HTTPStrategy {
        case onlyPost, onlyGet
        case queryOnlyGet, mutationOnlyPost
        case splitQueryAndMutation
    }

    public enum WebsocketProtocol {
        case subscriptionsTransportWs
        case graphqlWs
        case disable
        var subProtocol: String {
            switch self {
            case .subscriptionsTransportWs:
                return "graphql-ws"
            case .graphqlWs:
                return "graphql-transport-ws"
            case .disable:
                return "none"
            }
        }
    }

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
        switch wsProtocol {
        case .disable:
            break
        default:
            applyWebSocket(on: router, at: [path, "websocket"])
        }
    }

    enum ResolveError: Error {
        case unableToParseQuery
        case unsupportedProtocol
    }

    private func applyPost(on router: RoutesBuilder, at path: PathComponent = "graphql", allowing: [OperationType]) {
        router.post(path) { req async throws -> Response in
            let request = try req.content.decode(GraphQLRequest.self)
            guard try allowed(from: request, allowing: allowing) else {
                throw GraphQLError(ResolveError.unableToParseQuery)
            }
            let result = try await schema
                .execute(
                    request: request.query,
                    resolver: resolver,
                    context: contextBuilder(req),
                    eventLoopGroup: req.eventLoop,
                    variables: request.variables ?? [:],
                    operationName: request.operationName
                )
                .get()
            return try await result.encodeResponse(status: .ok, for: req)
        }
    }

    private func applyGet(on router: RoutesBuilder, at path: PathComponent = "graphql", allowing: [OperationType]) {
        router.get(path) { req async throws -> Response in
            guard let query: String = req.query[String.self, at: "query"] else {
                throw GraphQLError(ResolveError.unableToParseQuery)
            }
            let variables: [String: Map]? = (req.query[String.self, at: "variables"]).flatMap { (str: String) in
                guard let data = str.data(using: .utf8) else { return nil }
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                return try? decoder.decode([String: Map]?.self, from: data)
            }
            let operationName: String? = req.query[String.self, at: "operationName"]
            guard try allowed(from: GraphQLRequest(query: query, operationName: operationName, variables: variables), allowing: allowing) else {
                throw GraphQLError(ResolveError.unableToParseQuery)
            }
            let result = try await schema
                .execute(
                    request: query,
                    resolver: resolver,
                    context: contextBuilder(req),
                    eventLoopGroup: req.eventLoop,
                    variables: variables ?? [:],
                    operationName: operationName
                )
                .get()
            return try await result.encodeResponse(status: .ok, for: req)
        }
    }

    private func applyWebSocket(on router: RoutesBuilder, at path: [PathComponent] = ["graphql", "websocket"]) {
        router.get(path) { req throws -> Response in
            // TODO
            guard let _ = req.headers[.secWebSocketProtocol].filter({ $0 == wsProtocol.subProtocol }).first else {
                throw GraphQLError(ResolveError.unsupportedProtocol)
            }
            return .init()
        }
    }

    private func allowed(from gql: GraphQLRequest, allowing: [OperationType]) throws -> Bool {
        do {
            let ast = try parse(source: Source(body: gql.query))
            return ast
                .definitions
                .compactMap {
                    guard let def = $0 as? OperationDefinition else {
                        return nil
                    }
                    return allowing.contains(def.operation)
                }
                .reduce(true) { $0 && $1 }
        } catch {
            throw GraphQLError(error)
        }
    }
}

extension GraphQLResult: Content { }