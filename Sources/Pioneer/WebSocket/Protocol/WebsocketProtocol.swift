//
//  WebsocketProtocol.swift
//  Pioneer
//
//  Created by d-exclaimation on 4:30 PM.
//

import struct Foundation.Data

public extension Pioneer {
    /// Websocket sub-protocol
    enum WebsocketProtocol: Sendable {
        /// `subscriptions-transport-ws/graphql-ws`
        @available(*, deprecated, message: "Legacy protocol: Use `.graphqlWs` instead")
        case subscriptionsTransportWs
        /// `graphql-ws/graphql-transport-ws`
        case graphqlWs
        /// Disabled
        case disable

        /// Name of the sub-protocol
        public var name: String {
            switch self {
            case .subscriptionsTransportWs:
                return "graphql-ws"
            case .graphqlWs:
                return "graphql-transport-ws"
            case .disable:
                return ""
            }
        }

        /// Whether sub-protocol is accepting any websocket message
        var isAccepting: Bool {
            if case .disable = self {
                return false
            }
            return true
        }

        /// Method for checking is header is using the appropriate websocket protocol
        func isValid(_ header: String) -> Bool {
            header.lowercased() == name.lowercased()
        }

        /// Parse message into intent with protocol specific specification
        func parse(_ data: Data) -> Intent {
            innerProtocol.decode(data)
        }

        func initialize(_ io: WebSocketable) {
            innerProtocol.initialize(io)
        }

        /// Inner protocol namespace
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
                    Pioneer(..., websocketProtocol: .graphqlWs)

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

        var pong: String {
            innerProtocol.pong
        }

        var keepAliveMessage: String {
            innerProtocol.keepAliveMessage
        }
    }
}
