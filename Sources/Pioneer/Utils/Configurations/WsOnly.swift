//
//  WsOnly.swift
//  Pioneer
//
//  Created by d-exclaimation on 15:23.
//

import struct Vapor.Abort
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
            contextBuilder: { req, _ in 
                if introspection, let isIntro = try? req.graphql.isIntrospection, isIntro {
                    return try await contextBuilder(req, [:], req.graphql)
                }
                throw Abort(.imATeapot, reason: "This GraphQL server disabled GraphQL throught HTTP. To enable it, change this Pioneer configuration")
            }, 
            httpStrategy: .onlyPost,
            websocketContextBuilder: contextBuilder,
            websocketProtocol: .disable,
            introspection: introspection, 
            playground: .apolloSandbox
        )
    }

    /// Configuration for a WebSocket only GraphQL server (excluding introspection through POST if allowed)
    /// - Parameters:
    ///   - schema: The GraphQL schema from GraphQLSwift/GraphQL
    ///   - resolver: The top level object
    ///   - context: The context builder
    ///   - websocketProtocol: The websocket sub-protocol used
    ///   - playground: The GraphQL IDE
    ///   - validationRules: Validation rules applied on every operations
    ///   - introspection: Allowing introspection
    static func wsOnly(
        using schema: GraphQLSchema,
        resolver: Resolver,
        context: @escaping @Sendable (Request, ConnectionParams, GraphQLRequest) async throws -> Context,
        websocketProtocol: Pioneer<Resolver, Context>.WebsocketProtocol,
        playground: Pioneer<Resolver, Context>.IDE,
        validationRules: Pioneer<Resolver, Context>.Validations = .none,
        introspection: Bool = true
    ) -> Self {
        .init(
            schema: schema, 
            resolver: resolver, 
            contextBuilder: { req, _ in 
                if introspection, let isIntro = try? req.graphql.isIntrospection, isIntro {
                    return try await context(req, [:], req.graphql)
                }
                throw Abort(.imATeapot, reason: "This GraphQL server disabled GraphQL throught HTTP. To enable it, change this Pioneer configuration")
            }, 
            httpStrategy: .onlyPost,
            websocketContextBuilder: context, 
            websocketProtocol: websocketProtocol, 
            introspection: introspection, 
            playground: playground,
            validationRules: validationRules
        )
    }

    /// Configuration for a WebSocket only GraphQL server (excluding introspection through POST if allowed)
    /// - Parameters:
    ///   - schema: The GraphQL schema from GraphQLSwift/GraphQL
    ///   - resolver: The top level object
    ///   - websocketProtocol: The websocket sub-protocol used
    ///   - playground: The GraphQL IDE
    ///   - validationRules: Validation rules applied on every operations
    ///   - introspection: Allowing introspection
    static func wsOnly(
        using schema: GraphQLSchema,
        resolver: Resolver,
        websocketProtocol: Pioneer<Resolver, Context>.WebsocketProtocol,
        playground: Pioneer<Resolver, Context>.IDE,
        validationRules: Pioneer<Resolver, Context>.Validations = .none,
        introspection: Bool = true
    ) -> Self where Context == Void {
        .init(
            schema: schema, 
            resolver: resolver, 
            contextBuilder: { req, _ in 
                guard introspection && (try? req.graphql.isIntrospection) ?? false else {
                    throw Abort(.imATeapot, 
                        reason: "This GraphQL server disabled GraphQL throught HTTP. To enable it, change this Pioneer configuration"
                    )
                }
            }, 
            httpStrategy: .onlyPost,
            websocketContextBuilder: { _, _, _ in }, 
            websocketProtocol: websocketProtocol, 
            introspection: introspection, 
            playground: playground,
            validationRules: validationRules
        )
    }
}