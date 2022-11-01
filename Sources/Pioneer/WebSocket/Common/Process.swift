//
//  Client.swift
//  Pioneer
//
//  Created by d-exclaimation on 11:49 PM.
//

import struct Foundation.UUID
import enum NIOWebSocket.WebSocketErrorCode
import class NIO.EventLoopFuture
import Vapor

extension Pioneer {
    /// Running and Valid GraphQL over Websocket connection
    struct Process: Identifiable {
        /// Unique process ID
        var id: UUID
        /// Websocket connection for this process
        var ws: ProcessingConsumer
        /// Context from request attached to this context
        var payload: Payload
        /// Request attached to this process
        var req: Request
        /// KeepAlive Task
        var keepAlive: Task<Void, Error>?

        init(
            id: UUID = UUID(), 
            ws: ProcessingConsumer, 
            payload: Payload, 
            req: Request, 
            keepAlive: Task<Void, Error>? = nil
        ) {
            self.id = id
            self.ws = ws
            self.payload = payload
            self.req = req
            self.keepAlive = keepAlive
        }

        /// Send a text message
        func send(_ s: String) {
            ws.send(msg: s)
        }

        /// Close with error code
        func close(code: WebSocketErrorCode = .normalClosure) async {
            try? await ws.close(code: code).get()
        }
    }
}

/// Any type of connection consumer
/// 
/// Used for:
/// - Creating a test WebSocket connection
/// - Making compatibility with other servers (TODO)
protocol ProcessingConsumer {
    /// Send a messsage to this websocket consumer
    /// - Parameter msg: The message to be sent
    func send<S>(msg: S) where S: Collection, S.Element == Character

    /// Close the connection
    /// - Parameter code: Error code to close the connection
    func close(code: WebSocketErrorCode) -> EventLoopFuture<Void>
}

extension WebSocket: ProcessingConsumer {
    func send<S>(msg: S) where S: Collection, S.Element == Character {
        send(msg)
    }
}
