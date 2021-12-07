//
//  Pioneer+WebSocket.swift
//  Pioneer
//
//  Created by d-exclaimation on 11:36 AM.
//  Copyright © 2021 d-exclaimation. All rights reserved.
//

import Foundation
import Vapor
import NIO
import NIOHTTP1
import GraphQL

typealias SwiftTimer = Foundation.Timer

extension Pioneer {
    /// Apply middleware through websocket
    func applyWebSocket(on router: RoutesBuilder, at path: [PathComponent] = ["graphql", "websocket"]) {
        router.get(path) { req throws -> Response in
            /// Explicitly handle Websocket upgrade with sub-protocol
            let protocolHeader: [String] = req.headers[.secWebSocketProtocol]
            guard let _ = protocolHeader.first(where: websocketProtocol.isValid) else {
                throw GraphQLError(ResolveError.unsupportedProtocol)
            }

            let header: HTTPHeaders = ["Sec-WebSocket-Protocol": websocketProtocol.name]
            func shouldUpgrade(req: Request) -> EventLoopFuture<HTTPHeaders?> {
                req.eventLoop.next().makeSucceededFuture(.some(header))
            }

            return req.webSocket(shouldUpgrade: shouldUpgrade) { req, ws in
                let res = Response()
                let ctx = contextBuilder(req, res)
                let process = Process(ws: ws, ctx: ctx, req: req)

                ws.sendPing()

                /// Scheduled keep alive message interval
                let timer = SwiftTimer.scheduledTimer(withTimeInterval: 12, repeats: true) { timer in
                    ws.send(websocketProtocol.keepAliveMessage)
                }


                ws.onText { _, txt in
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

    /// On Websocket message callback
    func onMessage(process: Process, timer: SwiftTimer, txt: String) async  -> Void {
        guard let data = txt.data(using: .utf8) else {
            // Shouldn't accept any message that aren't utf8 string
            // -> Close with 1003 code
            await process.close(code: .unacceptableData)
            return
        }

        switch websocketProtocol.parse(data) {

        // Initial sub-protocol handshake established
        // Dispatch process to probe so it can start accepting operations
        // Timer fired here to keep connection alive by sub-protocol standard
        case .initial:
            await probe.task(with: .connect(process: process))
            timer.fire()
            websocketProtocol.initialize(ws: process.ws)

        // Ping is for requesting server to send a keep alive message
        case .ping:
            process.send(websocketProtocol.keepAliveMessage)

        // Explicit message to terminate connection to deallocate resources, stop timer, and close connection
        case .terminate:
            await probe.task(with: .disconnect(pid: process.id))
            timer.invalidate()
            await process.close(code: .goingAway)

        // Start -> Long running operation
        case .start(oid: let oid, gql: let gql):
            // Introspection guard
            guard case .some(true) = try? allowed(from: gql) else {
                let err = GraphQLMessage.errors(id: oid, type: websocketProtocol.error, [
                    .init(message: "GraphQL introspection is not allowed by Pioneer, but the query contained __schema or __type.")
                ])
                return process.send(err.jsonString)
            }
            await probe.task(with: .start(
                pid: process.id,
                oid: oid,
                gql: gql
            ))

        // Once -> Short lived operation
        case .once(oid: let oid, gql: let gql):
            // Introspection guard
            guard case .some(true) = try? allowed(from: gql) else {
                let err = GraphQLMessage.errors(id: oid, type: websocketProtocol.error, [
                    .init(message: "GraphQL introspection is not allowed by Pioneer, but the query contained __schema or __type.")
                ])
                return process.send(err.jsonString)
            }
            await probe.task(with: .once(
                pid: process.id,
                oid: oid,
                gql: gql
            ))

        // Stop -> End any running operation
        case .stop(oid: let oid):
            await probe.task(with: .stop(
                pid: process.id,
                oid: oid
            ))

        // Error in validation should notify that no operation will be run, does not close connection
        case .error(oid: let oid, message: let message):
            let err = GraphQLMessage.errors(id: oid, type: websocketProtocol.error, [.init(message: message)])
            process.send(err.jsonString)

        // Fatal error is an event trigger when message given in unacceptable by protocol standard
        // This message if processed any further will cause securities vulnerabilities, thus connection should be closed
        case .fatal(message: let message):
            let err = GraphQLMessage.errors(type: websocketProtocol.error, [.init(message: message)])
            process.send(err.jsonString)

            // Deallocation of resources
            await probe.task(with: .disconnect(pid: process.id))
            timer.invalidate()
            await process.close(code: .policyViolation)

        case .ignore:
            break
        }
    }

    /// On closing connection callback
    func onEnd(pid: UUID, timer: SwiftTimer) -> Void {
        probe.tell(with: .disconnect(pid: pid))
        timer.invalidate()
    }
}