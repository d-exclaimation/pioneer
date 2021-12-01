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
            innerProtocol.decode(data)
        }

        func initialize(ws: WebSocket) {
            innerProtocol.initialize(ws: ws)
        }

        private var innerProtocol: SubProtocol.Type {
            switch self {
            case .graphqlWs:
                return GraphQLWs.self
            case .subscriptionsTransportWs:
                return SubscriptionTransportWs.self
            case .disable:
                preconditionFailure(
                    """
                    Pioneer's websocket functionality is disabled.
                    There shouldn't be a need for parsing websocket messages and this line of code should never be ran.

                    If you are seeing this failure, try enabling Pioneer Websocket feature or using a guard to make sure it is not disabled
                    ```
                    // Enabling Websocket 
                    Pioneer(..., websocketProtocol: .subscriptionTransportWs)

                    // or use guards
                    if case .disable = pioneer.wsProtocol { return }
                    // or
                    guard wsProtocol.isAccepting else { return }
                    ```
                    """
                )
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
