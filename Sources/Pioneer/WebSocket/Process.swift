//
//  Client.swift
//  Pioneer
//
//  Created by d-exclaimation on 11:49 PM.
//  Copyright © 2021 d-exclaimation. All rights reserved.
//

import Foundation
import NIOWebSocket
import Vapor

extension Pioneer {
    /// Running and Valid GraphQL over Websocket connection
    struct Process: Identifiable {
        /// Unique process ID
        var id: UUID = UUID()
        /// Websocket connection for this process
        var ws: WebSocket
        /// Context from request attached to this context
        var ctx: Context
        /// Request attached to this process
        var req: Request

        /// Send a text message
        func send(_ s: String) {
            ws.send(s)
        }

        /// Close with error code
        func close(code: WebSocketErrorCode = .normalClosure) async {
            try? await ws.close(code: code).get()
        }
    }
}