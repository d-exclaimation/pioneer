//
//  Default.swift
//  Pioneer
//
//  Created by d-exclaimation on 20:12.
//

import class Vapor.Request
import class Vapor.Response
import class GraphQL.GraphQLSchema

public extension Pioneer.Config {
    /// Default configuration for Pioneer
    /// - Parameters:
    ///   - schema: The GraphQL schema from GraphQLSwift/GraphQL
    ///   - resolver: The top level object
    ///   - context: The context builder for HTTP
    ///   - websocketContext: The context builder for WebSocket
    ///   - introspection: Allowing introspection
    static func `default`(
        using schema: GraphQLSchema, 
        resolver: Resolver, 
        context: @escaping @Sendable (Request, Response) async throws -> Context,
        websocketContext: @escaping @Sendable (Request, ConnectionParams, GraphQLRequest) async throws -> Context,
        introspection: Bool = true
    ) -> Self {
        .init(
            schema: schema, 
            resolver: resolver, 
            contextBuilder: context, 
            httpStrategy: .queryOnlyGet, 
            websocketContextBuilder: websocketContext,
            websocketProtocol: .graphqlWs,
            introspection: introspection,
            playground: .apolloSandbox
        )
    }


    /// Default configuration for Pioneer
    /// - Parameters:
    ///   - schema: The GraphQL schema from GraphQLSwift/GraphQL
    ///   - resolver: The top level object
    ///   - context: The shared context builder
    ///   - introspection: Allowing introspection
    static func `default`(
        using schema: GraphQLSchema, 
        resolver: Resolver, 
        context: @escaping @Sendable (Request, Response) async throws -> Context,
        introspection: Bool = true
    ) -> Self {
        .init(
            schema: schema, 
            resolver: resolver, 
            contextBuilder: context, 
            httpStrategy: .queryOnlyGet, 
            websocketContextBuilder: { try await $0.defaultWebsocketContextBuilder(payload: $1, gql: $2, contextBuilder: context) },
            websocketProtocol: .graphqlWs,
            introspection: introspection,
            playground: .apolloSandbox
        )
    }

    /// Default configuration for Pioneer
    /// - Parameters:
    ///   - schema: The GraphQL schema from GraphQLSwift/GraphQL
    ///   - resolver: The top level object
    ///   - introspection: Allowing introspection
    static func `default`(
        using schema: GraphQLSchema, 
        resolver: Resolver, 
        introspection: Bool = true
    ) -> Self where Context == Void {
        .default(
            using: schema, 
            resolver: resolver,
            context: { _, _ in }, 
            websocketContext: { _, _, _ in }, 
            introspection: introspection
        )
    }
}