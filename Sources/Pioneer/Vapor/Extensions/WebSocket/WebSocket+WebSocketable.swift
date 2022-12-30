//
//  WebSocket+WebSocketable.swift
//  pioneer
//
//  Created by d-exclaimation on 14:35.
//

import enum NIOWebSocket.WebSocketErrorCode
import class Vapor.WebSocket

extension WebSocket: WebSocketable {
    public func out<S>(_ msg: S) where S: Collection, S.Element == Character {
        send(msg)
    }

    public func terminate(code: WebSocketErrorCode) async throws {
        try await close(code: code)
    }
}
