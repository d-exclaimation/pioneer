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
    static func simpleWsOnly(
        using schema: GraphQLSchema, 
        with resolver: Resolver, 
        allowing introspection: Bool = true
    ) -> Self where Context == Void {
        .simpleWsOnly(using: schema, with: resolver, and: { _, _, _ in }, allowing: introspection)
    }

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
            playground: .graphiql
        )
    }
}