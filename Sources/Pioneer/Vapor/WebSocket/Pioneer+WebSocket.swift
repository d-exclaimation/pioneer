//
//  Pioneer+WebSocket.swift
//  Pioneer
//
//  Created by d-exclaimation on 11:36 AM.
//

import Vapor
import struct GraphQL.GraphQLError

extension Pioneer {
    /// Vapor-based WebSocket Context builder
    public typealias VaporWebSocketContext = @Sendable (Request, Payload, GraphQLRequest) async throws -> Context

    /// Vapor-based WebSocket Guard
    public typealias VaporWebSocketGuard = @Sendable (Request, Payload) async throws -> Void

    /// Upgrade Handler for all GraphQL through Websocket
    /// - Parameter req: Request made to upgrade to Websocket
    /// - Returns: Response to upgrade connection to Websocket
    public func webSocketHandler(req: Request, context: @escaping VaporWebSocketContext, guard: @escaping VaporWebSocketGuard) async throws -> Response {
        /// Explicitly handle Websocket upgrade with sub-protocol
        let protocolHeader: [String] = req.headers[.secWebSocketProtocol]
        guard let _ = protocolHeader.first(where: websocketProtocol.isValid) else {
            return try GraphQLError(
                message: "Unrecognized websocket protocol. Specify the 'sec-websocket-protocol' header with '\(websocketProtocol.name)'"
            )
            .response(with: .badRequest)
        } 

        return req.webSocket(shouldUpgrade: shouldUpgrade(req:), onUpgrade: { 
            onUpgrade(req: $0, ws: $1, context: context, guard: `guard`) 
        })
    }
    
    /// Should upgrade callback
    func shouldUpgrade(req: Request) -> EventLoopFuture<HTTPHeaders?> {
        req.eventLoop.next().makeSucceededFuture(.init([("Sec-WebSocket-Protocol", websocketProtocol.name)]))
    }

    /// On upgrade callback
    func onUpgrade(req: Request, ws: WebSocket, context: @escaping VaporWebSocketContext, guard: @escaping VaporWebSocketGuard) -> Void {
        let pid = UUID()

        let keepAlive = setInterval(delay: keepAlive) {
            if ws.isClosed {
                throw Abort(.conflict, reason: "WebSocket closed before termination")
            }
            ws.send(websocketProtocol.keepAliveMessage)
        }

        let timeout = setTimeout(delay: timeout) {
            try await ws.close(code: .graphqlInitTimeout)
            keepAlive?.cancel()
        }

        ws.onText { _, txt in
            Task {
                await receiveMessage(
                    pid: pid, io: ws, 
                    keepAlive: keepAlive, 
                    timeout: timeout,
                    ev: req.eventLoop, 
                    txt: txt,
                    context: {
                        try await context(req, $0, $1)
                    },
                    check: {
                        try await `guard`(req, $0)
                    }
                )
            }
        }
                
        ws.onClose.whenComplete { _ in
            closeClient(pid: pid, keepAlive: keepAlive, timeout: timeout)
        } 
    }
}
