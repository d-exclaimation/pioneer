//
//  Graphiti+Config.swift
//  Pioneer
//
//  Created by d-exclaimation on 13:16.
//

import class Vapor.Request
import class Vapor.Response
import struct Vapor.Environment
import class Graphiti.Schema

public extension Pioneer.Config {
    // MARK: - Detect config

    /// Detect the configuration from the environment variables
    /// 
    /// Details on Environment variables used:
    /// - HTTPStrategy from `PIONEER_HTTP_STRATEGY` with values (`get`, `post`, `queryonlyget`, `mutationonlypost`, `split`, `csrf`, or `both`)
    /// - WebSocketProtocol from `PIONEER_WEBSOCKET_PROTOCOL` with values (`graphql-ws` or `subscriptions-transport-ws`)
    /// - Introspection from `PIONEER_INTROSPECTION` with any values meant true
    /// - GraphQL IDE from `PIONEER_PLAYGROUND` with values (`graphiql`, `apollo`, `sandbox`, or `bananacakepop`)
    /// - Keep alive interval from `PIONEER_KEEP_ALIVE` with any number in nanoseconds (leave empty to use default, otherwise interval is disabled)
    /// 
    /// - Parameters:
    ///   - schema: The GraphQL schema from Graphiti
    ///   - resolver: The top level object
    ///   - context: The context builder for HTTP
    ///   - websocketContext: The context bbuilder for WebSocket
    static func detect(
        using schema: Schema<Resolver, Context>, 
        resolver: Resolver, 
        context: @escaping @Sendable (Request, Response) async throws -> Context,
        websocketContext: @escaping @Sendable (Request, ConnectionParams, GraphQLRequest) async throws -> Context
    ) throws -> Self {
        try .detect(using: schema.schema, resolver: resolver, context: context, websocketContext: websocketContext)
    }

    // MARK: - Secured config

    /// Default secured configuration for Pioneer
    /// - Parameters:
    ///   - schema: The GraphQL schema from Graphiti
    ///   - resolver: The top level object
    ///   - context: The context builder for HTTP
    ///   - websocketContext: The context builder for WebSocket
    ///   - introspection: Allowing introspection
    static func secured(
        using schema: Schema<Resolver, Context>, 
        resolver: Resolver, 
        context: @escaping @Sendable (Request, Response) async throws -> Context,
        websocketContext: @escaping @Sendable (Request, ConnectionParams, GraphQLRequest) async throws -> Context,
        introspection: Bool = true
    ) -> Self {
        .secured(
            using: schema.schema, 
            resolver: resolver, 
            context: context, 
            websocketContext: websocketContext,
            introspection: introspection
        )
    }

    /// Default secured configuration for Pioneer
    /// - Parameters:
    ///   - schema: The GraphQL schema from Graphiti
    ///   - resolver: The top level object
    ///   - context: The shared context builder
    ///   - websocketContext: The context builder for WebSocket
    ///   - introspection: Allowing introspection
    static func secured(
        using schema: Schema<Resolver, Context>, 
        resolver: Resolver, 
        context: @escaping @Sendable (Request, Response) async throws -> Context,
        introspection: Bool = true
    ) -> Self {
        .secured(
            using: schema.schema, 
            resolver: resolver, 
            context: context, 
            introspection: introspection
        )
    }

    // MARK: - Default config
    
    /// Default configuration for Pioneer
    /// - Parameters:
    ///   - schema: The GraphQL schema from Graphiti
    ///   - resolver: The top level object
    ///   - context: The context builder for HTTP
    ///   - websocketContext: The context builder for WebSocket
    ///   - introspection: Allowing introspection
    static func `default`(
        using schema: Schema<Resolver, Context>, 
        resolver: Resolver, 
        context: @escaping @Sendable (Request, Response) async throws -> Context,
        websocketContext: @escaping @Sendable (Request, ConnectionParams, GraphQLRequest) async throws -> Context,
        introspection: Bool = true
    ) -> Self {
        .default(
            using: schema.schema, 
            resolver: resolver, 
            context: context, 
            websocketContext: websocketContext,
            introspection: introspection
        )
    }


    /// Default configuration for Pioneer
    /// - Parameters:
    ///   - schema: The GraphQL schema from Graphiti
    ///   - resolver: The top level object
    ///   - context: The shared context builder
    ///   - introspection: Allowing introspection
    static func `default`(
        using schema: Schema<Resolver, Context>, 
        resolver: Resolver, 
        context: @escaping @Sendable (Request, Response) async throws -> Context,
        introspection: Bool = true
    ) -> Self {
        .default(
            using: schema.schema, 
            resolver: resolver, 
            context: context, 
            introspection: introspection
        )
    }

    // MARK: - HTTP Only

    /// Configuration for only HTTP only GraphQl server
    /// - Parameters:
    ///   - schema: The GraphQL server from GraphQLSwift/GraphQL
    ///   - resolver: The top level object
    ///   - context: The context builder
    ///   - httpStrategy: The routing strategy
    ///   - playground: The GraphQL IDE used
    ///   - introspection: Allowing introspection
    /// - Returns: 
    static func httpOnly(
        using schema: Schema<Resolver, Context>, 
        resolver: Resolver, 
        context: @escaping @Sendable (Request, Response) async throws -> Context,
        httpStrategy: Pioneer<Resolver, Context>.HTTPStrategy,
        playground: Pioneer<Resolver, Context>.IDE,
        introspection: Bool = true  
    ) -> Self {
        .httpOnly(
            using: schema.schema, 
            resolver: resolver, 
            context: context, 
            httpStrategy: httpStrategy, 
            playground: playground,
            introspection: introspection
        )
    }

    // MARK: - Simple HTTP Only

     /// Simple configuration for HTTP only GraphQL server
    /// - Parameters:
    ///   - schema: The GraphQL schema from GraphQLSwift/GraphQL
    ///   - resolver: The top level object
    ///   - contextBuilder: The context builder
    ///   - introspection: Allowing introspection
    static func simpleHttpOnly(
        using schema: Schema<Resolver, Context>, 
        with resolver: Resolver, 
        and contextBuilder: @escaping @Sendable (Request, Response) async throws -> Context,
        allowing introspection: Bool = true
    ) -> Self {
        .simpleHttpOnly(using: schema.schema, with: resolver, and: contextBuilder, allowing: introspection)
    }

    // MARK: - WebSocket Only

    /// Configuration for a WebSocket only GraphQL server (excluding introspection through POST if allowed)
    /// - Parameters:
    ///   - schema: The GraphQL schema from GraphQLSwift/GraphQL
    ///   - resolver: The top level object
    ///   - context: The context builder
    ///   - websocketProtocol: The websocket sub-protocol used
    ///   - playground: The GraphQL IDE
    ///   - introspection: Allowing introspection
    static func wsOnly(
        using schema: Schema<Resolver, Context>,
        resolver: Resolver,
        context: @escaping @Sendable (Request, ConnectionParams, GraphQLRequest) async throws -> Context,
        websocketProtocol: Pioneer<Resolver, Context>.WebsocketProtocol,
        playground: Pioneer<Resolver, Context>.IDE,
        introspection: Bool = true
    ) -> Self {
        .wsOnly(
            using: schema.schema, 
            resolver: resolver, 
            context: context, 
            websocketProtocol: websocketProtocol, 
            playground: playground, 
            introspection: introspection
        )
    }

    // MARK: - Simple WebSocket Only

    /// Simple configuration for WebSocket GraphQL server
    /// - Parameters:
    ///   - schema: The GraphQL schema from GraphQLSwift/GraphQL
    ///   - resolver: The top level object
    ///   - contextBuilder: The context builder
    ///   - introspection: Allowing introspection
    static func simpleWsOnly(
        using schema: Schema<Resolver, Context>, 
        with resolver: Resolver, 
        and contextBuilder: @escaping @Sendable (Request, ConnectionParams, GraphQLRequest) async throws -> Context,
        allowing introspection: Bool = true
    ) -> Self {
        .simpleWsOnly(using: schema.schema, with: resolver, and: contextBuilder, allowing: introspection)
    }
}