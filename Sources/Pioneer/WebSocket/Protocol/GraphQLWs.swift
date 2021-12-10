//
//  GraphQLWs.swift
//  Pioneer
//
//  Created by d-exclaimation on 4:58 PM.
//

import Foundation
import Vapor

/// GraphQL Over Websocket Protocol namespace for `graphql-ws/graphql-transport-ws`
enum GraphQLWs: SubProtocol {
    static let name: String = "graphql-transport-ws"
    
    private static let Subscribe = "subscribe"
    private static let Next = "next"
    private static let Error = "error"
    private static let Complete = "complete"

    private static let Ping = "ping"
    private static let Pong = "pong"
    private static let ConnectionAck = "connection_ack"
    private static let ConnectionInit = "connection_init"

    static func decode<Resolver, Context>(_ data: Data) -> Pioneer<Resolver, Context>.Intent {
        guard let msg = data.to(GraphQLMessage.self) else {
            return .fatal(message: "Invalid operation message type")
        }
        switch (msg.type, msg.payload, msg.id) {
        /// Start an operation whether it is `query`, `mutation`, and `subscriptions`
        case (Subscribe, .some(let payload), .some(let oid)):
            return parseOperation(oid: oid, payload: payload)

        // Stop an operation using the OID
        case (Complete, .none, .some(let oid)):
            return .stop(oid: oid)

        // Initialize handshake and confirm connection
        case (ConnectionInit, _, .none):
            return .initial

        // A request to validate active connection
        case (Ping, _, .none):
            return .ping

        // A callback from validation active connection
        case (Pong, _, _):
            return .ignore

        default:
            return .fatal(message: "Invalid operation message type")
        }
    }

    static func initialize(ws: ProcessingConsumer) {
        let ack = GraphQLMessage(type: ConnectionAck)
        ws.send(msg: ack.jsonString)
    }

    static var next: String { Next }

    static var complete: String { Complete }

    static var error: String { Error }

    static var keepAliveMessage: String { GraphQLMessage(type: ConnectionAck).jsonString }

}
