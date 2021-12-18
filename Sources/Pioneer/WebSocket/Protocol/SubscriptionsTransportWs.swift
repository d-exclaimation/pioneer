//
//  SubscriptionsTransportWs.swift
//  Pioneer
//
//  Created by d-exclaimation on 1:11 PM.
//

import Foundation
import GraphQL
import Vapor

/// GraphQL Over Websocket Protocol namespace for `subscriptions-transport-ws/graphql-ws`
enum SubscriptionTransportWs: SubProtocol {
    static let name: String = "graphql-ws"

    private static let GQL_START = "start"
    private static let GQL_STOP = "stop"
    private static let GQL_DATA = "data"
    private static let GQL_ERROR = "error"
    private static let GQL_COMPLETE = "complete"

    private static let GQL_CONNECTION_TERMINATE = "connection_terminate"
    private static let GQL_CONNECTION_KEEP_ALIVE = "ka"
    private static let GQL_CONNECTION_ACK = "connection_ack"
    private static let GQL_CONNECTION_INIT = "connection_init"

    static func decode<Resolver, Context>(_ data: Data) -> Pioneer<Resolver, Context>.Intent {
        guard let msg = data.to(GraphQLMessage.self) else {
            return .fatal(message: "Invalid operation message type")
        }
        switch (msg.type, msg.payload, msg.id) {
        /// Start an operation whether it is `query`, `mutation`, and `subscriptions`
        case (GQL_START, .some(let payload), .some(let oid)):
            return parseOperation(oid: oid, payload: payload)

        // Stop an operation using the OID
        case (GQL_STOP, .none, .some(let oid)):
            return .stop(oid: oid)

        // Initialize handshake and confirm connection
        case (GQL_CONNECTION_INIT, _, .none):
            return .initial
        // De-initialize handshake and terminate connection
        case (GQL_CONNECTION_TERMINATE, .none, .none):
            return .terminate

        default:
            return .fatal(message: "Invalid operation message type")
        }
    }

    static func initialize(ws: ProcessingConsumer) {
        let ack = GraphQLMessage(type: GQL_CONNECTION_ACK)
        let ka = GraphQLMessage(type: GQL_CONNECTION_KEEP_ALIVE)
        ws.send(msg: ack.jsonString)
        ws.send(msg: ka.jsonString)
    }
    
    static var next: String { GQL_DATA }

    static var complete: String { GQL_COMPLETE }

    static var error: String { GQL_ERROR }

    static var keepAliveMessage: String {
        GraphQLMessage(type: GQL_CONNECTION_KEEP_ALIVE)
            .jsonString
    }
}
