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
    ///   - validationRules: Validation rules to be applied for every operations
    ///   - introspection: Allowing introspection
    static func `default`(
        using schema: GraphQLSchema, 
        resolver: Resolver, 
        context: @Sendable @escaping (Request, Response) async throws -> Context,
        websocketContext: @Sendable @escaping (Request, ConnectionParams, GraphQLRequest) async throws -> Context,
        validationRules: Pioneer<Resolver, Context>.Validations = .none,
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
            playground: .apolloSandbox,
            validationRules: validationRules
        )
    }


    /// Default configuration for Pioneer
    /// - Parameters:
    ///   - schema: The GraphQL schema from GraphQLSwift/GraphQL
    ///   - resolver: The top level object
    ///   - context: The shared context builder
    ///   - validationRules: Validation rules to be applied for every operations
    ///   - introspection: Allowing introspection
    static func `default`(
        using schema: GraphQLSchema, 
        resolver: Resolver, 
        context: @Sendable @escaping (Request, Response) async throws -> Context,
        validationRules: Pioneer<Resolver, Context>.Validations = .none,
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
            playground: .apolloSandbox,
            validationRules: validationRules
        )
    }

    /// Default configuration for Pioneer
    /// - Parameters:
    ///   - schema: The GraphQL schema from GraphQLSwift/GraphQL
    ///   - resolver: The top level object
    ///   - validationRules: Validation rules to be applied for every operations
    ///   - introspection: Allowing introspection
    static func `default`(
        using schema: GraphQLSchema, 
        resolver: Resolver, 
        validationRules: Pioneer<Resolver, Context>.Validations = .none,
        introspection: Bool = true
    ) -> Self where Context == Void {
        .default(
            using: schema, 
            resolver: resolver,
            context: { _, _ in }, 
            websocketContext: { _, _, _ in }, 
            validationRules: validationRules,
            introspection: introspection
        )
    }
}