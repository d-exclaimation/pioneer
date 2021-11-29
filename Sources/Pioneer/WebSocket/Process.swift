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
    struct Process: Identifiable {
        var id: UUID = UUID()
        var ws: WebSocket
        var ctx: Context
        var req: Request

        func send(_ s: String) {
            ws.send(s)
        }

        func close(code: WebSocketErrorCode = .normalClosure) async {
            try? await ws.close(code: code).get()
        }
    }
}