//
//  Client.swift
//  Pioneer
//
//  Created by d-exclaimation on 11:49 PM.
//

import Foundation
import NIOWebSocket
import NIO
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

        init(id: UUID = UUID(), ws: ProcessingConsumer, payload: ConnectionParams, req: Request) {
            self.id = id
            self.ws = ws
            self.payload = payload
            self.req = req
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
