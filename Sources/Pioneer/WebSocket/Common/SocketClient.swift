//
//  SocketClient.swift
//  pioneer
//
//  Created by d-exclaimation on 14:40.
//

import Foundation
import enum NIOWebSocket.WebSocketErrorCode
import class NIO.EventLoopFuture
import protocol NIO.EventLoopGroup

extension Pioneer {
    public typealias WebSocketGuard = @Sendable (Payload) async throws -> Void

    public typealias WebSocketContext = @Sendable (Payload, GraphQLRequest) async throws -> Context

    public struct SocketClient {
        var id: UUID
        var io: SocketIO
        var payload: Payload
        var ev: EventLoopGroup
        var contextBuilder: WebSocketContext

        init(id: UUID, io: SocketIO, payload: Payload, ev: EventLoopGroup, context: @escaping WebSocketContext) {
            self.id = id
            self.io = io
            self.payload = payload
            self.ev = ev
            self.contextBuilder = context
        }

        public func out(_ json: String) {
            io.out(json)
        }

        public func terminate(code: WebSocketErrorCode) async {
            try? await io.terminate(code: code)
        }

        public func context(_ gql: GraphQLRequest) async throws -> Context {
            try await contextBuilder(payload, gql)
        }
    }
}