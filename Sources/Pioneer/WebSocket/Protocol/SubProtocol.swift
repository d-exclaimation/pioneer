//
//  ScopedProtocol.swift
//  Pioneer
//
//  Created by d-exclaimation on 1:24 PM.
//

import struct Foundation.Data
import enum GraphQL.Map
import enum NIOWebSocket.WebSocketErrorCode

/// GraphQL Over Websocket sub-protocol
protocol SubProtocol {
    /// Decode incoming websocket message into GraphQL Intent so that it can handled properly with static typing
    static func decode<Resolver, Context>(_ data: Data) -> Pioneer<Resolver, Context>.Intent

    /// Protocol specific initialization after acknowledgement message
    static func initialize(_ io: WebSocketable)

    /// Next data typename for this sub-protocol
    static var next: String { get }
    /// Completion typename for this sub-protocol
    static var complete: String { get }
    /// Error typename for this sub-protocol
    static var error: String { get }
    /// Pong type namefor this sub-protocol
    static var pong: String { get }
    /// Keep alive message being sent on an interval to keep connection going
    static var keepAliveMessage: String { get }
}

extension SubProtocol {
    /// Parse an operation based on the payload JSON given
    /// - Parameters:
    ///   - oid: The operation id decided by the server
    ///   - payload: The JSON payload
    /// - Returns: The intent based on the payload
    static func parseOperation<Resolver, Context>(oid: String, payload: [String: Map]) -> Pioneer<Resolver, Context>.Intent {
        guard let query = payload["query"]?.string else {
            return .error(oid: oid, message: "Cannot find query in request")
        }

        let operationName = payload["operationName"]?.string
        let variables = payload["variables"]?.dictionary?.unordered()
        let gql = GraphQLRequest(query: query, operationName: operationName, variables: variables)

        guard let operation = gql.operationType else {
            return .error(oid: oid, message: "Non spec compliant operation type")
        }
        switch operation {
        case .query, .mutation:
            return .once(oid: oid, gql: gql)
        case .subscription:
            return .start(oid: oid, gql: gql)
        }
    }
}

extension WebSocketErrorCode {
    static var graphqlNotAuthorized: WebSocketErrorCode {
        .init(codeNumber: 4401)
    }

    static var graphqlInitTimeout: WebSocketErrorCode {
        .init(codeNumber: 4408)
    }

    static var graphqlInvalid: WebSocketErrorCode {
        .init(codeNumber: 4400)
    }
}
