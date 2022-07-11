//
//  WsOnly.swift
//  Pioneer
//
//  Created by d-exclaimation on 15:23.
//

import class Vapor.Request
import class Vapor.Response
import class GraphQL.GraphQLSchema

public extension Pioneer.Config {
    /// Simple configuration for WebSocket GraphQL server
    /// - Parameters:
    ///   - schema: The GraphQL schema from GraphQLSwift/GraphQL
    ///   - resolver: The top level object
    ///   - introspection: Allowing introspection
    static func simpleWsOnly(
        using schema: GraphQLSchema, 
        with resolver: Resolver, 
        allowing introspection: Bool = true
    ) -> Self where Context == Void {
        .simpleWsOnly(using: schema, with: resolver, and: { _, _, _ in }, allowing: introspection)
    }

    /// Simple configuration for WebSocket GraphQL server
    /// - Parameters:
    ///   - schema: The GraphQL schema from GraphQLSwift/GraphQL
    ///   - resolver: The top level object
    ///   - contextBuilder: The context builder
    ///   - introspection: Allowing introspection
    static func simpleWsOnly(
        using schema: GraphQLSchema, 
        with resolver: Resolver, 
        and contextBuilder: @escaping @Sendable (Request, ConnectionParams, GraphQLRequest) async throws -> Context,
        allowing introspection: Bool = true
    ) -> Self {
        .init(
            schema: schema, 
            resolver: resolver, 
            contextBuilder: { req, res in 
                try await contextBuilder(req, [:], req.graphql)
            }, 
            websocketContextBuilder: contextBuilder,
            websocketProtocol: .disable,
            introspection: introspection, 
            playground: .apolloSandbox
        )
    }
}