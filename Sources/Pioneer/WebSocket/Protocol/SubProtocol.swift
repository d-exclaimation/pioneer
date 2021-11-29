//
//  ScopedProtocol.swift
//  Pioneer
//
//  Created by d-exclaimation on 1:24 PM.
//  Copyright © 2021 d-exclaimation. All rights reserved.
//

import Foundation
import GraphQL
import Vapor

protocol SubProtocol {
    static func decode<Resolver, Context>(_ data: Data) -> Pioneer<Resolver, Context>.Intent
    static func initialize(ws: WebSocket)
    static var next: String { get }
    static var complete: String { get }
    static var error: String { get }
    static var keepAliveMessage: String { get }
}

extension SubProtocol {
    static func parseOperation<Resolver, Context>(oid: String, payload: [String: Map]) -> Pioneer<Resolver, Context>.Intent {
        guard let query = payload["query"]?.string else {
            return .error(oid: oid, message: "Cannot find query in request")
        }

        let operationName = payload["operationName"]?.string
        let variables = payload["variables"]?.dictionary?.unordered()

        guard let operation = try? GraphQLRequest(query: query, operationName: operationName, variables: variables).operationType() else {
            return .error(oid: oid, message: "Non spec compliant operation type")
        }
        switch operation {
        case .query, .mutation:
            return .once(oid: oid, query: query, op: operationName, vars: variables ?? [:])
        case .subscription:
            return .start(oid: oid, query: query, op: operationName, vars: variables ?? [:])
        }
    }
}