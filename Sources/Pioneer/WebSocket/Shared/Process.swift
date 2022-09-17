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
        var payload: ConnectionParams
        /// Request attached to this process
        var req: Request
        /// KeepAlive Task
        var keepAlive: Task<Void, Error>?

        init(
            id: UUID = UUID(), 
            ws: ProcessingConsumer, 
            payload: ConnectionParams, 
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

protocol ProcessingConsumer {
    func send<S>(msg: S) where S: Collection, S.Element == Character
    func close(code: WebSocketErrorCode) -> EventLoopFuture<Void>
}

extension WebSocket: ProcessingConsumer {
    func send<S>(msg: S) where S: Collection, S.Element == Character {
        send(msg)
    }
}
