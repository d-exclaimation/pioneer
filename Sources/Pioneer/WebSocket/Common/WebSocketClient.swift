//
//  WebSocketClient.swift
//  pioneer
//
//  Created by d-exclaimation on 14:40.
//

import Foundation
import class NIO.EventLoopFuture
import protocol NIO.EventLoopGroup
import enum NIOWebSocket.WebSocketErrorCode

public extension Pioneer {
    /// WebSocket initialisation guard
    typealias WebSocketGuard = @Sendable (Payload) async throws -> Void

    /// WebSocket Context Builder
    typealias WebSocketContext = @Sendable (Payload, GraphQLRequest) async throws -> Context

    /// Full GraphQL over WebSocket Client
    struct WebSocketClient: Identifiable {
        /// The unique key for this client
        public var id: UUID

        /// The WebSocket output
        public var io: WebSocketable

        /// The payload given during initialisation
        public var payload: Payload

        /// Any event loop
        public var ev: EventLoopGroup

        /// Context builder for this client
        public var contextBuilder: WebSocketContext

        /// Create a GraphQL over WebSocket client
        /// - Parameters:
        ///   - id: The unique key for this client
        ///   - io: The WebSocket output
        ///   - payload: The payload given during initialisation
        ///   - ev: Any event loop
        ///   - context: Context builder for this client
        public init(id: UUID, io: WebSocketable, payload: Payload, ev: EventLoopGroup, context: @escaping WebSocketContext) {
            self.id = id
            self.io = io
            self.payload = payload
            self.ev = ev
            self.contextBuilder = context
        }

        /// Send message to the WebSocket output
        /// - Parameter json: The JSON string to be sent
        public func out(_ json: String) {
            io.out(json)
        }

        /// Terminate the client
        /// - Parameter code: Error code for the termination
        public func terminate(code: WebSocketErrorCode) async {
            try? await io.terminate(code: code)
        }

        /// Build context for a specific operation
        /// - Parameter gql: The GraphQL request
        /// - Returns: The context
        public func context(_ gql: GraphQLRequest) async throws -> Context {
            try await contextBuilder(payload, gql)
        }
    }
}
