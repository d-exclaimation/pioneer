//
//  Request+WebSocket.swift
//  pioneer
//
//  Created by d-exclaimation on 12:10.
//

import class Vapor.Request

extension Request {
    /// Check if ths request is an upgrade to WebSocket request
    public var isWebSocketUpgrade: Bool {
        guard let connection = headers.first(name: .connection), let upgrade = headers.first(name: .upgrade) else {
            return false
        }
        return connection.lowercased() == "upgrade" && upgrade.lowercased() == "websocket"
    }
}