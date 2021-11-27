//
//  Pioneer+RequestContext.swift
//  Pioneer
//
//  Created by d-exclaimation on 9:46 PM.
//  Copyright © 2021 d-exclaimation. All rights reserved.
//

import Foundation
import Vapor
import Graphiti

public extension Pioneer where Context == Request {
    init(
        schema: Schema<Resolver, Request>,
        resolver: Resolver,
        httpStrategy: HTTPStrategy = .queryOnlyGet,
        wsProtocol: WebsocketProtocol = .subscriptionsTransportWs
    ) {
        self.init(schema: schema, resolver: resolver, contextBuilder: { $0 }, httpStrategy: httpStrategy, wsProtocol: wsProtocol)
    }
}
