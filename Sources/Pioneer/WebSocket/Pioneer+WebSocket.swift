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
                    ws.send(wsProtocol.keepAliveMessage)
                }

                ws.onText { ws, txt in
                    Task.init {
                        await onMessage(ctx: ctx, pid: pid, ws: ws, timer: timer, txt: txt)
                    }
                }

                ws.onClose.whenComplete { _ in
                    onEnd(pid: pid, timer: timer)
                }
            }
        }
    }

    func onMessage(ctx: Context, pid: UUID, ws: WebSocket, timer: Timer, txt: String) async  -> Void {
        guard let data = txt.data(using: .utf8) else {
            Task.init { try await ws.close(code: .unacceptableData).get() }
            return
        }
        switch wsProtocol.parse(data) {

        case .initial:
            // TODO: Connect to Proxy actor
            timer.fire()
            wsProtocol.initialize(ws: ws)

        case .ping:
            ws.send(wsProtocol.keepAliveMessage)

        case .terminate:
            timer.invalidate()
            try? await ws.close(code: .policyViolation).get()

        case .start(oid: let oid, query: let query, op: let op, vars: let vars):
            // TODO: Start long running operation
            break

        case .once(oid: let oid, query: let query, op: let op, vars: let vars):
            // TODO: Start short lived operation
            break

        case .stop(oid: let oid):
            // TODO: Any running operation
            break

        case .error(oid: let oid, message: let message):
            // Send back error message
            let error = Map.dictionary(["message": .string(message)])
            let errorMessage = GraphQLMessage.Variance(id: oid, type: wsProtocol.error, payload: .array([error]))
            ws.send(errorMessage.jsonString)

        case .fatal(message: let message):
            timer.invalidate()
            let error = Map.dictionary(["message": .string(message)])
            let errorMessage = GraphQLMessage.Variance(id: nil, type: wsProtocol.error, payload: .array([error]))
            ws.send(errorMessage.jsonString)
            try? await ws.close(code: .unacceptableData).get()

        case .ignore:
            break
        }
    }

    func onEnd(pid: UUID, timer: Timer) -> Void {
        // TODO: Deallocate resources
        timer.invalidate()
    }
}