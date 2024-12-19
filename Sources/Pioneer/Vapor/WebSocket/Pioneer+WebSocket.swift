//
//  Pioneer+WebSocket.swift
//  Pioneer
//
//  Created by d-exclaimation on 11:36 AM.
//

import struct GraphQL.GraphQLError
import Vapor

public extension Pioneer {
    /// Vapor-based WebSocket Context builder
    typealias VaporWebSocketContext = @Sendable (Request, Payload, GraphQLRequest) async throws -> Context

    /// Vapor-based WebSocket Guard
    typealias VaporWebSocketGuard = @Sendable (Request, Payload) async throws -> Void

    /// Upgrade Handler for all GraphQL through Websocket
    /// - Parameter req: Request made to upgrade to Websocket
    /// - Returns: Response to upgrade connection to Websocket
    func webSocketHandler(req: Request, context: @escaping VaporWebSocketContext, guard: @escaping VaporWebSocketGuard) async throws -> Response {
        /// Explicitly handle Websocket upgrade with sub-protocol
        let protocolHeader: [String] = req.headers[.secWebSocketProtocol]
            .flatMap { $0.split(separator: ",") }
            .map { String($0) }
            .map { $0.trimmingCharacters(in: .whitespaces) }

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
    @Sendable
    internal func shouldUpgrade(req: Request) -> EventLoopFuture<HTTPHeaders?> {
        req.eventLoop.makeSucceededFuture(.init([("Sec-WebSocket-Protocol", websocketProtocol.name)]))
    }

    /// On upgrade callback
    internal func onUpgrade(req: Request, ws: WebSocket, context: @escaping VaporWebSocketContext, guard: @escaping VaporWebSocketGuard) {
        let cid = UUID()

        // Tasks for handling keep alive internal and connectiontimeout
        let keepAlive = keepAlive(using: ws)
        let timeout = timeout(using: ws, keepAlive: keepAlive)


        // Synchronously consume WebSocket messages as a stream to avoid wrapping in a Task and cyclic references
        let stream = AsyncStream(String.self) { con in
            ws.onText { con.yield($1) }

            con.onTermination = { @Sendable _ in
                guard ws.isClosed else { return }
                _ = ws.close()
            }
        }

        // Task for consuming WebSocket messages collected from the stream 
        let receiving = Task {
            for await message in stream {
                await receiveMessage(
                    cid: cid, io: ws,
                    keepAlive: keepAlive,
                    timeout: timeout,
                    ev: req.eventLoop,
                    txt: message,
                    context: {
                        try await context(req, $0, $1)
                    },
                    check: {
                        try await `guard`(req, $0)
                    }
                )
            }
        }

        // Task for closing websocket and disposing any references
        Task {
            try await ws.onClose.get()
            receiving.cancel()
            disposeClient(cid: cid, keepAlive: keepAlive, timeout: timeout)
        }
    }
}
