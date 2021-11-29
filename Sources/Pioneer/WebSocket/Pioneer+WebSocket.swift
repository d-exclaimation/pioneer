//
//  Pioneer+WebSocket.swift
//  Pioneer
//
//  Created by d-exclaimation on 11:36 AM.
//  Copyright © 2021 d-exclaimation. All rights reserved.
//

import Foundation
import Vapor
import GraphQL

extension Pioneer {
    func applyWebSocket(on router: RoutesBuilder, at path: [PathComponent] = ["graphql", "websocket"]) {
        router.get(path) { req throws -> Response in
            let protocolHeader: [String] = req.headers[.secWebSocketProtocol]
            guard let _ = protocolHeader.filter(wsProtocol.isValid).first else {
                throw GraphQLError(ResolveError.unsupportedProtocol)
            }
            return req.webSocket { req, ws in
                let pid = UUID()
                let ctx = contextBuilder(req)

                let timer = Timer.scheduledTimer(withTimeInterval: 12, repeats: true) { timer in
                    ws.send("TODO: keep this connection alive")
                }

                ws.onText { ws, txt in
                    onMessage(ctx: ctx, pid: pid, ws: ws, timer: timer, txt: txt)
                }

                ws.onClose.whenComplete { _ in
                    onEnd(pid: pid, timer: timer)
                }
            }
        }
    }

    func onMessage(ctx: Context, pid: UUID, ws: WebSocket, timer: Timer, txt: String) -> Void {
        guard let data = txt.data(using: .utf8) else {
            Task.init { try await ws.close(code: .unacceptableData).get() }
            return
        }
        switch wsProtocol.parse(data) {
        case .initial:
            break
        case .ping:
            break
        case .terminate:
            break
        case .ignore:
            break
        case .start(oid: let oid, query: let query, op: let op, vars: let vars):
            break
        case .once(oid: let oid, query: let query, op: let op, vars: let vars):
            break
        case .stop(oid: let oid):
            break
        case .error(oid: let oid, message: let message):
            break
        case .fatal(message: let message):
            break
        }
    }

    func onEnd(pid: UUID, timer: Timer) -> Void {
        // TODO: Deallocate resources
        timer.invalidate()
    }
}