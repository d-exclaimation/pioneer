//
//  HttpOnly.swift
//  Pioneer
//
//  Created by d-exclaimation on 15:22.
//

import class Vapor.Request
import class Vapor.Response
import class GraphQL.GraphQLSchema

public extension Pioneer.Config {
    static func simpleHttpOnly(
        using schema: GraphQLSchema, 
        with resolver: Resolver, 
        allowing introspection: Bool = true
    ) -> Self where Context == Void {
        .simpleHttpOnly(using: schema, with: resolver, and: {_, _ in }, allowing: introspection)
    }

    static func simpleHttpOnly(
        using schema: GraphQLSchema, 
        with resolver: Resolver, 
        and contextBuilder: @escaping @Sendable (Request, Response) async throws -> Context,
        allowing introspection: Bool = true
    ) -> Self {
        .init(
            schema: schema, 
            resolver: resolver, 
            contextBuilder: contextBuilder, 
            websocketContextBuilder: { req, params, gql in 
                try await req.defaultWebsocketContextBuilder(payload: params, gql: gql, contextBuilder: contextBuilder) 
            },
            websocketProtocol: .disable,
            introspection: introspection, 
            playground: .graphiql
        )
    }
}