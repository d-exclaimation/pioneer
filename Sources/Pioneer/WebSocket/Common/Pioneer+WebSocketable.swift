//
//  Pioneer+WebSocketable.swift
//  pioneer
//
//  Created by d-exclaimation on 15:38.
//

import enum NIOWebSocket.WebSocketErrorCode

public extension Pioneer {
    /// Create a WebSocket connection ping / keep alive interval given the configuration
    /// - Parameter io: any WebSocket output
    func keepAlive(using io: WebSocketable) -> Task<Void, Error>? {
        setInterval(delay: keepAlive) {
            io.out(websocketProtocol.keepAliveMessage)
        }
    }

    /// Create a WebSocket connectiontimeout given the configuration
    /// - Parameter io: any WebSocket output
    func timeout(using io: WebSocketable, keepAlive: Task<Void, Error>? = nil) -> Task<Void, Error>? {
        setTimeout(delay: timeout) {
            try await io.terminate(code: .graphqlInitTimeout)
            keepAlive?.cancel()
        }
    }
}
