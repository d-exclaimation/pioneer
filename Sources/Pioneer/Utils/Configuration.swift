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
        /// Validation rules 
        let validationRules: Validations
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
            validationRules: Validations = .none,
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
            self.validationRules = validationRules
            self.keepAlive = keepAlive
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
            validationRules: config.validationRules,
            keepAlive: config.keepAlive
        )
    }
}