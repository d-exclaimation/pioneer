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
    typealias Clock = Foundation.Timer
    func applyWebSocket(on router: RoutesBuilder, at path: [PathComponent] = ["graphql", "websocket"]) {
        router.get(path) { req throws -> Response in
            let protocolHeader: [String] = req.headers[.secWebSocketProtocol]
            guard let _ = protocolHeader.filter(wsProtocol.isValid).first else {
                throw GraphQLError(ResolveError.unsupportedProtocol)
            }
            return req.webSocket { req, ws in
                let ctx = contextBuilder(req)
                let process = Process(ws: ws, ctx: ctx, req: req)

                let timer = Timer.scheduledTimer(withTimeInterval: 12, repeats: true) { timer in
                    ws.send(wsProtocol.keepAliveMessage)
                }

                ws.onText { ws, txt in
                    Task.init {
                        await onMessage(process: process, timer: timer, txt: txt)
                    }
                }

                ws.onClose.whenComplete { _ in
                    onEnd(pid: process.id, timer: timer)
                }
            }
        }
    }

    func onMessage(process: Process, timer: Clock, txt: String) async  -> Void {
        guard let data = txt.data(using: .utf8) else {
            await process.close(code: .unacceptableData)
            return
        }

        switch wsProtocol.parse(data) {

        case .initial:
            await probe.task(with: .connect(process: process))
            timer.fire()
            wsProtocol.initialize(ws: process.ws)

        case .ping:
            process.send(wsProtocol.keepAliveMessage)

        case .terminate:
            await probe.task(with: .disconnect(pid: process.id))
            timer.invalidate()
            await process.close(code: .goingAway)

        case .start(oid: let oid, query: let query, op: let op, vars: let vars):
            await probe.task(with: .start(pid: process.id, oid: oid, query: query, ctx: process.ctx, vars: vars, op: op))

        case .once(oid: let oid, query: let query, op: let op, vars: let vars):
            await probe.task(with: .once(pid: process.id, oid: oid, query: query, ctx: process.ctx, vars: vars, op: op))

        case .stop(oid: let oid):
            await probe.task(with: .stop(pid: process.id, oid: oid))

        case .error(oid: let oid, message: let message):
            let error = Map.dictionary(["message": .string(message)])
            let errorMessage = GraphQLMessage.Variance(id: oid, type: wsProtocol.error, payload: .array([error]))
            process.send(errorMessage.jsonString)

        case .fatal(message: let message):
            let error = Map.dictionary(["message": .string(message)])
            let errorMessage = GraphQLMessage.Variance(id: nil, type: wsProtocol.error, payload: .array([error]))

            await probe.task(with: .disconnect(pid: process.id))
            timer.invalidate()
            process.send(errorMessage.jsonString)
            await process.close(code: .policyViolation)

        case .ignore:
            break
        }
    }

    func onEnd(pid: UUID, timer: Clock) -> Void {
        probe.tell(with: .disconnect(pid: pid))
        timer.invalidate()
    }
}