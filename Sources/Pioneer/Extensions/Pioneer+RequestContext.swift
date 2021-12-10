//
//  Pioneer+RequestContext.swift
//  Pioneer
//
//  Created by d-exclaimation on 9:46 PM.
//

import Foundation
import Graphiti

public extension Pioneer where Context == Void {
    /// - Parameters:
    ///   - schema: Graphiti schema used to execute operations
    ///   - resolver: Resolver used by the GraphQL schema
    ///   - httpStrategy: HTTP strategy
    ///   - websocketProtocol: Websocket sub-protocol
    ///   - introspection: Allowing introspection
    ///   - playground: Allowing playground
    init(
        schema: Schema<Resolver, Void>,
        resolver: Resolver,
        httpStrategy: HTTPStrategy = .queryOnlyGet,
        websocketProtocol: WebsocketProtocol = .subscriptionsTransportWs,
        introspection: Bool = true,
        playground: Bool = true
    ) {
        self.init(
            schema: schema.schema,
            resolver: resolver,
            contextBuilder: { _, _ in },
            httpStrategy: httpStrategy,
            websocketProtocol: websocketProtocol,
            introspection: introspection,
            playground: playground
        )
    }
}
