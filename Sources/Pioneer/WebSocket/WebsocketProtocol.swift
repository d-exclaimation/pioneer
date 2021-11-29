//
//  WebsocketProtocol.swift
//  Pioneer
//
//  Created by d-exclaimation on 4:30 PM.
//  Copyright © 2021 d-exclaimation. All rights reserved.
//

import Foundation

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
            .ignore
        }
    }
}
