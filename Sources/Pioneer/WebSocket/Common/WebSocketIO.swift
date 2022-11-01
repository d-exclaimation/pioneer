//
//  WebSocketIO.swift
//  pioneer
//
//  Created by d-exclaimation on 14:31.
//

import enum NIOWebSocket.WebSocketErrorCode

/// Any WebSocket output that can send messages and be terminated 
public protocol WebSocketIO {
    /// Send a messsage to this websocket consumer
    /// - Parameter msg: The message to be sent
    func out<S>(_ msg: S) where S: Collection, S.Element == Character

    /// Close the connection
    /// - Parameter code: Error code to close the connection
    func terminate(code: WebSocketErrorCode) async throws 
}