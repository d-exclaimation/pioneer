//
//  Pioneer+Graphiti.swift
//  Pioneer
//
//  Created by d-exclaimation on 9:46 PM.
//  Copyright © 2021 d-exclaimation. All rights reserved.
//

import Graphiti
import Vapor

public extension Pioneer {
    /// - Parameters:
    ///   - schema: GraphQL schema used to execute operations
    ///   - resolver: Resolver used by the GraphQL schema
    ///   - contextBuilder: Context builder from request
    ///   - httpStrategy: HTTP strategy
    ///   - websocketProtocol: Websocket sub-protocol
    ///   - introspection: Allowing introspection
    ///   - playground: Allowing playground
    init(
        schema: Schema<Resolver, Context>,
        resolver: Resolver,
        contextBuilder: @escaping (Request, Response) -> Context,
        httpStrategy: HTTPStrategy = .queryOnlyGet,
        websocketProtocol: WebsocketProtocol = .subscriptionsTransportWs,
        introspection: Bool = true,
        playground: Bool = true
    ) {
        self.init(
            schema: schema.schema,
            resolver: resolver,
            contextBuilder: contextBuilder,
            httpStrategy: httpStrategy,
            websocketProtocol: websocketProtocol,
            introspection: introspection,
            playground: playground
        )
    }
}
