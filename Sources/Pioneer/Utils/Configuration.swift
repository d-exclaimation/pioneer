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
    /// Configuration for Pioneer
    public struct Config {
        /// Graphiti schema used to execute operations
        let schema: GraphQLSchema
        /// Resolver used by the GraphQL schema
        let resolver: Resolver
        /// Context builder from request
        let contextBuilder: @Sendable (Request, Response) async throws -> Context
        /// HTTP strategy
        let httpStrategy: Pioneer<Resolver, Context>.HTTPStrategy 
        /// Websocket Context builder
        let websocketContextBuilder: @Sendable (Request, ConnectionParams, GraphQLRequest) async throws -> Context
        /// Websocket sub-protocol
        let websocketProtocol: Pioneer<Resolver, Context>.WebsocketProtocol
        /// Allowing introspection
        let introspection: Bool
        /// Allowing GraphQL IDE
        let playground: Pioneer<Resolver, Context>.IDE 
        /// Keep alive period
        let keepAlive: UInt64?

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

        /// Default configuration for Pioneer
        /// - Parameters:
        ///   - schema: The GraphQL schema from GraphQLSwift/GraphQL
        ///   - resolver: The top level object
        ///   - context: The context builder for HTTP
        ///   - websocketContext: The context builder for WebSocket
        ///   - introspection: Allowing introspection
        public static func `default`(
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
        public static func `default`(
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
        public static func `default`(
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

        /// Default secured configuration for Pioneer
        /// - Parameters:
        ///   - schema: The GraphQL schema from GraphQLSwift/GraphQL
        ///   - resolver: The top level object
        ///   - context: The context builder for HTTP
        ///   - websocketContext: The context builder for WebSocket
        ///   - introspection: Allowing introspection
        public static func secured(
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
                httpStrategy: .csrfPrevention, 
                websocketContextBuilder: websocketContext,
                websocketProtocol: .graphqlWs,
                introspection: introspection,
                playground: .apolloSandbox
            )
        }

        /// Default secured configuration for Pioneer
        /// - Parameters:
        ///   - schema: The GraphQL schema from GraphQLSwift/GraphQL
        ///   - resolver: The top level object
        ///   - context: The shared context builder
        ///   - websocketContext: The context builder for WebSocket
        ///   - introspection: Allowing introspection
        public static func secured(
            using schema: GraphQLSchema, 
            resolver: Resolver, 
            context: @escaping @Sendable (Request, Response) async throws -> Context,
            introspection: Bool = true
        ) -> Self {
            .init(
                schema: schema, 
                resolver: resolver, 
                contextBuilder: context, 
                httpStrategy: .csrfPrevention, 
                websocketContextBuilder: { try await $0.defaultWebsocketContextBuilder(payload: $1, gql: $2, contextBuilder: context) },
                websocketProtocol: .graphqlWs,
                introspection: introspection,
                playground: .apolloSandbox
            )
        }

        /// Default secured configuration for Pioneer
        /// - Parameters:
        ///   - schema: The GraphQL schema from GraphQLSwift/GraphQL
        ///   - resolver: The top level object
        ///   - introspection: Allowing introspection
        public static func secured(
            using schema: GraphQLSchema, 
            resolver: Resolver, 
            introspection: Bool = true
        ) -> Self where Context == Void {
            .secured(
                using: schema, 
                resolver: resolver, 
                context: { _, _ in }, 
                websocketContext: { _, _, _ in },
                introspection: introspection
            )
        }
    }
}

public extension Pioneer {
    init(_ config: Config) {
        self.init(
            schema: config.schema, 
            resolver: config.resolver, 
            contextBuilder: config.contextBuilder, 
            httpStrategy: config.httpStrategy,
            websocketContextBuilder: config.websocketContextBuilder,
            websocketProtocol: config.websocketProtocol,
            introspection: config.introspection,
            playground: config.playground,
            keepAlive: config.keepAlive
        )
    }
}