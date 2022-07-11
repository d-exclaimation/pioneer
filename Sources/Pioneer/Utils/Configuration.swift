//
//  Configuration.swift
//  Pioneer
//
//  Created by d-exclaimation on 14:57.
//

import class Vapor.Request
import class Vapor.Response
import class GraphQL.GraphQLSchema

extension Pioneer {
    public struct Config {
        /// Graphiti schema used to execute operations
        var schema: GraphQLSchema
        /// Resolver used by the GraphQL schema
        var resolver: Resolver
        /// Context builder from request
        var contextBuilder: @Sendable (Request, Response) async throws -> Context
        /// HTTP strategy
        var httpStrategy: Pioneer<Resolver, Context>.HTTPStrategy 
        /// Websocket Context builder
        var websocketContextBuilder: @Sendable (Request, ConnectionParams, GraphQLRequest) async throws -> Context
        /// Websocket sub-protocol
        var websocketProtocol: Pioneer<Resolver, Context>.WebsocketProtocol
        /// Allowing introspection
        var introspection: Bool
        /// Allowing GraphQL IDE
        var playground: Pioneer<Resolver, Context>.IDE 
        /// Keep alive period
        var keepAlive: UInt64?

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
        }
    }

}
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
