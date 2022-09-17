//
//  Pioneer+RequestContext.swift
//  Pioneer
//
//  Created by d-exclaimation on 9:46 PM.
//

import class Graphiti.Schema

public extension Pioneer where Context == Void {
    /// - Parameters:
    ///   - schema: Graphiti schema used to execute operations
    ///   - resolver: Resolver used by the GraphQL schema
    ///   - httpStrategy: HTTP strategy
    ///   - websocketProtocol: Websocket sub-protocol
    ///   - introspection: Allowing introspection
    ///   - playground: Allowing playground
    ///   - validationRules: Validation rules to be applied before operation
    ///   - keepAlive: Keep alive internal in nanosecond, default to 12.5 sec, nil for disable
    ///   - timeout: Timeout interval in nanosecond, default to 5 sec, nil for disable
    init(
        schema: Schema<Resolver, Void>,
        resolver: Resolver,
        httpStrategy: HTTPStrategy = .queryOnlyGet,
        websocketProtocol: WebsocketProtocol = .graphqlWs,
        introspection: Bool = true,
        playground: IDE = .graphiql,
        validationRules: Validations = .none,
        keepAlive: UInt64? = 12_500_000_000,
        timeout: UInt64? = 5_000_000_000
    ) {
        self.init(
            schema: schema.schema,
            resolver: resolver,
            contextBuilder: { _, _ in },
            httpStrategy: httpStrategy,
            websocketContextBuilder: { _, _, _ in },
            websocketProtocol: websocketProtocol,
            introspection: introspection,
            playground: playground,
            validationRules: validationRules,
            keepAlive: keepAlive,
            timeout: timeout
        )
    }
}
