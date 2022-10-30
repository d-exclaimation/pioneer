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
        /// Websocket handler function for initialization phase
        let websocketOnInit: @Sendable (ConnectionParams) async throws -> Void
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
        /// Timeout period
        let timeout: UInt64?

        public init(
            schema: GraphQLSchema,
            resolver: Resolver,
            contextBuilder: @Sendable @escaping (Request, Response) async throws -> Context,
            httpStrategy: HTTPStrategy = .queryOnlyGet,
            websocketContextBuilder: @Sendable @escaping (Request, ConnectionParams, GraphQLRequest) async throws -> Context,
            websocketOnInit: @Sendable @escaping (ConnectionParams) async throws -> Void = { _ in },
            websocketProtocol: WebsocketProtocol = .graphqlWs,
            introspection: Bool = true,
            playground: IDE = .sandbox,
            validationRules: Validations = .none,
            keepAlive: UInt64? = 12_500_000_000,
            timeout: UInt64? = 5_000_000_000
        ) {
            self.schema = schema
            self.resolver = resolver
            self.contextBuilder = contextBuilder
            self.httpStrategy = httpStrategy
            self.websocketContextBuilder = websocketContextBuilder
            self.websocketOnInit = websocketOnInit
            self.websocketProtocol = websocketProtocol
            self.introspection = introspection
            self.playground = !introspection ? .disable : playground
            self.validationRules = validationRules
            self.keepAlive = keepAlive
            self.timeout = timeout
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
            websocketOnInit: config.websocketOnInit,
            websocketProtocol: config.websocketProtocol,
            introspection: config.introspection,
            playground: config.playground,
            validationRules: config.validationRules,
            keepAlive: config.keepAlive,
            timeout: config.timeout
        )
    }
}