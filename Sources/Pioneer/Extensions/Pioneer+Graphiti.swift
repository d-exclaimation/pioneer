//
//  Pioneer+Graphiti.swift
//  Pioneer
//
//  Created by d-exclaimation on 9:46 PM.
//

import class Graphiti.Schema
import class Vapor.Request
import class Vapor.Response

public extension Pioneer {
    /// - Parameters:
    ///   - schema: GraphQL schema used to execute operations
    ///   - resolver: Resolver used by the GraphQL schema
    ///   - contextBuilder: Context builder from request
    ///   - httpStrategy: HTTP strategy
    ///   - websocketProtocol: Websocket sub-protocol
    ///   - introspection: Allowing introspection
    ///   - playground: Allowing playground
    ///   - validationRules: Validation rules to be applied before operation
    ///   - keepAlive: Keep alive internal in nanosecond, default to 12.5 sec, nil for disable
    init(
        schema: Schema<Resolver, Context>,
        resolver: Resolver,
        contextBuilder: @escaping @Sendable (Request, Response) async throws -> Context,
        httpStrategy: HTTPStrategy = .queryOnlyGet,
        websocketProtocol: WebsocketProtocol = .graphqlWs,
        introspection: Bool = true,
        playground: IDE = .graphiql,
        validationRules: Validations = .none,
        keepAlive: UInt64? = 12_500_000_000
    ) {
        self.init(
            schema: schema.schema,
            resolver: resolver,
            contextBuilder: contextBuilder,
            httpStrategy: httpStrategy,
            websocketContextBuilder: { @Sendable req, payload, gql async throws in
                try await req.defaultWebsocketContextBuilder(
                    payload: payload,
                    gql: gql,
                    contextBuilder: contextBuilder
                )
            },
            websocketProtocol: websocketProtocol,
            introspection: introspection,
            playground: playground,
            validationRules: validationRules,
            keepAlive: keepAlive
        )
    }
    
    /// - Parameters:
    ///   - schema: GraphQL schema used to execute operations
    ///   - resolver: Resolver used by the GraphQL schema
    ///   - contextBuilder: Context builder from request
    ///   - httpStrategy: HTTP strategy
    ///   - websocketContextBuilder: Context builder for the websocket
    ///   - websocketProtocol: Websocket sub-protocol
    ///   - introspection: Allowing introspection
    ///   - playground: Allowing playground
    ///   - validationRules: Validation rules to be applied before operation
    ///   - keepAlive: Keep alive internal in nanosecond, default to 12.5 sec, nil for disable
    init(
        schema: Schema<Resolver, Context>,
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
        self.init(
            schema: schema.schema,
            resolver: resolver,
            contextBuilder: contextBuilder,
            httpStrategy: httpStrategy,
            websocketContextBuilder: websocketContextBuilder,
            websocketProtocol: websocketProtocol,
            introspection: introspection,
            playground: playground,
            validationRules: validationRules,
            keepAlive: keepAlive
        )
    }
}
