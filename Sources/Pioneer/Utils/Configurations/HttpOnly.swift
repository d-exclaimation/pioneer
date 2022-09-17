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
    /// Simple configuration for HTTP only GraphQL server
    /// - Parameters:
    ///   - schema: The GraphQL schema from GraphQLSwift/GraphQL
    ///   - resolver: The top level object
    ///   - introspection: Allowing introspection
    static func simpleHttpOnly(
        using schema: GraphQLSchema, 
        with resolver: Resolver, 
        allowing introspection: Bool = true
    ) -> Self where Context == Void {
        .simpleHttpOnly(using: schema, with: resolver, and: {_, _ in }, allowing: introspection)
    }

    /// Simple configuration for HTTP only GraphQL server
    /// - Parameters:
    ///   - schema: The GraphQL schema from GraphQLSwift/GraphQL
    ///   - resolver: The top level object
    ///   - contextBuilder: The context builder
    ///   - introspection: Allowing introspection
    static func simpleHttpOnly(
        using schema: GraphQLSchema, 
        with resolver: Resolver, 
        and contextBuilder: @Sendable @escaping (Request, Response) async throws -> Context,
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

    /// Configuration for only HTTP only GraphQl server
    /// - Parameters:
    ///   - schema: The GraphQL server from GraphQLSwift/GraphQL
    ///   - resolver: The top level object
    ///   - context: The context builder
    ///   - httpStrategy: The routing strategy
    ///   - playground: The GraphQL IDE used
    ///   - validationRules: Validation rules applied on every operations
    ///   - introspection: Allowing introspection
    /// - Returns: 
    static func httpOnly(
        using schema: GraphQLSchema, 
        resolver: Resolver, 
        context: @Sendable @escaping (Request, Response) async throws -> Context,
        httpStrategy: Pioneer<Resolver, Context>.HTTPStrategy,
        playground: Pioneer<Resolver, Context>.IDE,
        validationRules: Pioneer<Resolver, Context>.Validations = .none,
        introspection: Bool = true  
    ) -> Self {
        .init(
            schema: schema, 
            resolver: resolver, 
            contextBuilder: context, 
            httpStrategy: httpStrategy, 
            websocketContextBuilder: { 
                try await $0.defaultWebsocketContextBuilder(payload: $1, gql: $2, contextBuilder: context)
            }, 
            websocketProtocol: .disable, 
            introspection: introspection, 
            playground: playground,
            validationRules: validationRules
        )
    }
    
    /// Configuration for only HTTP only GraphQl server
    /// - Parameters:
    ///   - schema: The GraphQL server from GraphQLSwift/GraphQL
    ///   - resolver: The top level object
    ///   - context: The context builder
    ///   - httpStrategy: The routing strategy
    ///   - playground: The GraphQL IDE used
    ///   - validationRules: Validation rules applied on every operations
    ///   - introspection: Allowing introspection
    /// - Returns: 
    static func httpOnly(
        using schema: GraphQLSchema, 
        resolver: Resolver, 
        httpStrategy: Pioneer<Resolver, Context>.HTTPStrategy,
        playground: Pioneer<Resolver, Context>.IDE,
        validationRules: Pioneer<Resolver, Context>.Validations = .none,
        introspection: Bool = true  
    ) -> Self where Context == Void {
        .httpOnly(
            using: schema, 
            resolver: resolver, 
            context: { _, _ in }, 
            httpStrategy: httpStrategy, 
            playground: playground, 
            validationRules: validationRules,
            introspection: introspection
        )
    }
}