//
//  WebsocketProtocol.swift
//  Pioneer
//
//  Created by d-exclaimation on 4:30 PM.
//  Copyright © 2021 d-exclaimation. All rights reserved.
//

import Foundation

extension Pioneer {
    public enum WebsocketProtocol {
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
                return "none"
            }
        }

        public var isAccepting: Bool {
            switch self {
            case .subscriptionsTransportWs, .graphqlWs:
                return true
            case .disable:
                return false
            }
        }

        public func isValid(_ header: String) -> Bool {
            header.lowercased() == subprotocol.lowercased()
        }
    }
}