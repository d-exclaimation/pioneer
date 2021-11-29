//
//  WebsocketProtocol.swift
//  Pioneer
//
//  Created by d-exclaimation on 4:30 PM.
//  Copyright © 2021 d-exclaimation. All rights reserved.
//

import Foundation
import Vapor
import Desolate

public extension Pioneer {
    enum WebsocketProtocol {
        case subscriptionsTransportWs
        case graphqlWs
        case disable

        public var subprotocol: String {
            switch self {
            case .subscriptionsTransportWs:
                return "graphql-ws"
            case .graphqlWs:
                return "graphql-transport-ws"
            case .disable:
                return ""
            }
        }
        var isAccepting: Bool {
            if case .disable = self {
                return false
            }
            return true
        }

        func isValid(_ header: String) -> Bool {
            header.lowercased() == subprotocol.lowercased()
        }

        func parse(_ data: Data) -> Intent {
            let proto = returns { () -> SubProtocol.Type? in
                switch self {
                case .subscriptionsTransportWs:
                    return SubscriptionTransportWs.self
                case .graphqlWs:
                    return GraphQLWs.self
                default:
                    return nil
                }
            }
            return proto?.decode(data) ?? Intent.terminate
        }

        func initialize(ws: WebSocket) {
            innerProtocol.initialize(ws: ws)
        }

        private var innerProtocol: SubProtocol.Type {
            switch self {
            case .graphqlWs:
                return GraphQLWs.self
            default:
                return SubscriptionTransportWs.self
            }
        }

        var next: String {
            innerProtocol.next
        }

        var error: String {
            innerProtocol.error
        }

        var complete: String {
            innerProtocol.complete
        }

        var keepAliveMessage: String {
            innerProtocol.keepAliveMessage
        }
    }
}
