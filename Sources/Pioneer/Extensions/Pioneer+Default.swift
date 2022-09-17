//  Pioneer+Default.swift
//  
//
//  Created by d-exclaimation on 18/06/22.
//

import class Vapor.Request
import class Vapor.Response
import class GraphQL.GraphQLSchema

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
    ///   - timeout: Timeout interval in nanosecond, default to 5 sec, nil for disable
    init(
        schema: GraphQLSchema,
        resolver: Resolver,
        contextBuilder: @Sendable @escaping (Request, Response) async throws -> Context,
        httpStrategy: HTTPStrategy = .queryOnlyGet,
        websocketProtocol: WebsocketProtocol = .graphqlWs,
        introspection: Bool = true,
        playground: IDE = .graphiql,
        validationRules: Validations = .none,
        keepAlive: UInt64? = 12_500_000_000,
        timeout: UInt64? = 5_000_000_000
    ) {
        self.init(
            schema: schema,
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
            keepAlive: keepAlive,
            timeout: timeout
        )
    }
}
