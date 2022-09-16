//
//  Pioneer+WebSocket.swift
//  Pioneer
//
//  Created by d-exclaimation on 11:36 AM.
//

import Vapor
import struct Foundation.UUID
import struct GraphQL.GraphQLError
import enum GraphQL.Map

public typealias ConnectionParams = [String: Map]?

extension Pioneer {
    /// KeepAlive Task
    typealias KeepAlive = Task<Void, Error>?
    
    /// Apply middleware through websocket
    func applyWebSocket(on router: RoutesBuilder, at path: [PathComponent] = ["graphql", "websocket"]) {
        router.get(path, use: webSocketHandler(req:))
    }

    /// Upgrade Handler for all GraphQL through Websocket
    /// - Parameter req: Request made to upgrade to Websocket
    /// - Returns: Response to upgrade connection to Websocket
    public func webSocketHandler(req: Request) async throws -> Response {
        /// Explicitly handle Websocket upgrade with sub-protocol
        let protocolHeader: [String] = req.headers[.secWebSocketProtocol]
        guard let _ = protocolHeader.first(where: websocketProtocol.isValid) else {
            return try GraphQLError(
                message: "Unrecognized websocket protocol. Specify the 'sec-websocket-protocol' header with '\(websocketProtocol.name)'"
            )
            .response(with: .badRequest)
        } 

        return req.webSocket(shouldUpgrade: wsShouldUpgrade(req:)) { req, ws in 
            let pid = UUID()
                
            ws.sendPing()
                
            /// Scheduled keep alive message interval
            let keepAlive: KeepAlive = setInterval(delay: 12_500_000_000) {
                if ws.isClosed {
                    throw Abort(.conflict, reason: "WebSocket closed before any termination")
                }
                ws.send(msg: websocketProtocol.keepAliveMessage)
            }
                
            ws.onText { _, txt in
                Task {
                    await onMessage(pid: pid, ws: ws, req: req, keepAlive: keepAlive, txt: txt)
                }
            }
                
            ws.onClose.whenComplete { _ in
                onEnd(pid: pid, keepAlive: keepAlive)
            } 
        }
    }
    
    /// Handler to send back upgraded connection headers
    /// - Parameter req: Request being made
    /// - Returns: The headers for making the upgrade
    func wsShouldUpgrade(req: Request) -> EventLoopFuture<HTTPHeaders?> {
        req.eventLoop.next().makeSucceededFuture(.init([("Sec-WebSocket-Protocol", websocketProtocol.name)]))
    }

    /// On Websocket message callback
    func onMessage(pid: UUID, ws: ProcessingConsumer, req: Request, keepAlive: KeepAlive, txt: String) async -> Void {
        guard let data = txt.data(using: .utf8) else {
            // Shouldn't accept any message that aren't utf8 string
            // -> Close with 1003 code
            try? await ws.close(code: .unacceptableData).get()
            return
        }

        switch websocketProtocol.parse(data) {

        // Initial sub-protocol handshake established
        // Dispatch process to probe so it can start accepting operations
        // Timer fired here to keep connection alive by sub-protocol standard
        case .initial(let payload):
            let process = Process(id: pid, ws: ws, payload: payload, req: req)
            await probe.connect(with: process)
            websocketProtocol.initialize(ws: ws)

        // Ping is for requesting server to send a keep alive message
        case .ping:
            ws.send(msg: websocketProtocol.keepAliveMessage)

        // Explicit message to terminate connection to deallocate resources, stop timer, and close connection
        case .terminate:
            await probe.disconnect(for: pid)
            keepAlive?.cancel()
            try? await ws.close(code: .goingAway).get()

        // Start -> Long running operation
        case .start(oid: let oid, gql: let gql):
            // Introspection guard
            guard allowed(from: gql) else {
                let err = GraphQLMessage.errors(id: oid, type: websocketProtocol.error, [
                    .init(message: "GraphQL introspection is not allowed by Pioneer, but the query contained __schema or __type.")
                ])
                return ws.send(msg: err.jsonString)
            }
            let errors = validationRules(using: schema, for: gql)
            guard errors.isEmpty else {
                let err = GraphQLMessage.errors(id: oid, type: websocketProtocol.error, errors)
                return ws.send(msg: err.jsonString)
            }

            await probe.start(
                for: pid,
                with: oid,
                given: gql
            )

        // Once -> Short lived operation
        case .once(oid: let oid, gql: let gql):
            // Introspection guard
            guard allowed(from: gql) else {
                let err = GraphQLMessage.errors(id: oid, type: websocketProtocol.error, [
                    .init(message: "GraphQL introspection is not allowed by Pioneer, but the query contained __schema or __type.")
                ])
                return ws.send(msg: err.jsonString)
            }
            let errors = validationRules(using: schema, for: gql)
            guard errors.isEmpty else {
                let err = GraphQLMessage.errors(id: oid, type: websocketProtocol.error, errors)
                return ws.send(msg: err.jsonString)
            }

            await probe.once(
                for: pid,
                with: oid,
                given: gql
            )

        // Stop -> End any running operation
        case .stop(oid: let oid):
            await probe.stop(
                for: pid,
                with: oid
            )

        // Error in validation should notify that no operation will be run, does not close connection
        case .error(oid: let oid, message: let message):
            let err = GraphQLMessage.errors(id: oid, type: websocketProtocol.error, [.init(message: message)])
            ws.send(msg: err.jsonString)

        // Fatal error is an event trigger when message given in unacceptable by protocol standard
        // This message if processed any further will cause securities vulnerabilities, thus connection should be closed
        case .fatal(message: let message):
            let err = GraphQLMessage.errors(type: websocketProtocol.error, [.init(message: message)])
            ws.send(msg: err.jsonString)

            // Deallocation of resources
            await probe.disconnect(for: pid)
            keepAlive?.cancel()
            try? await ws.close(code: .policyViolation).get()

        case .ignore:
            break
        }
    }

    /// On closing connection callback
    func onEnd(pid: UUID, keepAlive: KeepAlive) -> Void {
        Task {
            await probe.disconnect(for: pid)
        }
        keepAlive?.cancel()
    }
}


@discardableResult func setInterval(delay: UInt64?, _ block: @Sendable @escaping () throws -> Void) -> Task<Void, Error>? {
    guard let delay = delay else {
        return nil
    }
    return Task {
        while !Task.isCancelled {
            try await Task.sleep(nanoseconds: delay)
            try block()
        }
    }
}
