//
//  Pioneer+Vapor.swift
//  pioneer
//
//  Created by d-exclaimation on 09:44.
//

import protocol Vapor.AsyncMiddleware
import class Vapor.Request
import class Vapor.Response
import enum Vapor.PathComponent
import enum Vapor.HTTPMethod
import enum Vapor.HTTPBodyStreamStrategy
import protocol Vapor.AsyncResponder

extension Pioneer {
    enum Direction {
        case operation, upgrade, playground, ignore
    }    

    public struct VaporGraphQLMiddleware: AsyncMiddleware {
        private let server: Pioneer
        private let path: [PathComponent] 
        private let body: HTTPBodyStreamStrategy
        private let context: VaporHTTPContext
        private let websocketContext: VaporWebSocketContext
        private let websocketGuard: VaporWebSocketGuard

        internal init(
            server: Pioneer, 
            path: [PathComponent],
            body: HTTPBodyStreamStrategy,
            context: @escaping VaporHTTPContext,
            websocketGuard: @escaping VaporWebSocketGuard = { _, _ in }
        ) {
            self.server = server
            self.path = path
            self.body = body
            self.context = context
            self.websocketContext = { 
                try await $0.defaultWebsocketContextBuilder(payload: $1, gql: $2, contextBuilder: context)
            }
            self.websocketGuard = websocketGuard
        }

        internal init(
            server: Pioneer, 
            path: [PathComponent],
            body: HTTPBodyStreamStrategy,
            context: @escaping VaporHTTPContext,
            websocketContext: @escaping VaporWebSocketContext,
            websocketGuard: @escaping VaporWebSocketGuard = { _, _ in }
        ) {
            self.server = server
            self.path = path
            self.body = body
            self.context = context
            self.websocketContext = websocketContext
            self.websocketGuard = websocketGuard
        }

        private func isGraphQLPath(to request: Request) -> Bool {
            let components = request
                .url.path
                .split(separator: "/", omittingEmptySubsequences: true)
                .map { String($0) }

            for i in path.indices {
                if i >= components.count {
                    return false
                }
                switch (path[i]) {
                    case .catchall:
                        return true
                    case .anything, .constant(components[i]):
                        continue
                    case .constant, .parameter:
                        return false
                }
            }
            return components.count == path.count
        }

        private func isGraphQLMethod(to request: Request) -> Bool {
            request.method == .POST || request.method == .GET
        }

        private func direction(to request: Request) async throws -> Direction {
            if request.method == .POST {
                return .operation
            }

            if server.websocketProtocol.isAccepting, let connection = request.headers.first(name: .connection), connection.lowercased() == "upgrade" {
                return .upgrade
            }

            if case .some = request.query[String.self, at: "query"] {
                return .operation
            }
            return server.playground == .disable ? .ignore : .playground
        }

        private func collect(_ request: Request) async throws -> Request {
            if case .collect(let max) = body, request.body.data == nil {
                let _ = try await request.body
                    .collect(max: max?.value ?? request.application.routes.defaultMaxBodySize.value)
                    .get()
                return request
            }
            return request 
        }

        public func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
            guard isGraphQLMethod(to: request) && isGraphQLPath(to: request) else {
                return try await next.respond(to: request)
            }

            switch try await direction(to: request) {
                case .operation:
                    return try await server.httpHandler(req: collect(request), context: context)
                case .upgrade:
                    return try await server.webSocketHandler(req: collect(request), context: websocketContext, guard: websocketGuard)
                case .playground:
                    return server.ideHandler(req: request)
                case .ignore:
                    return try await next.respond(to: request)
            }
        }
    }

    /// Pioneer GraphQL handlers for Vapor
    /// - Parameters:
    ///   - body: The body streaming strategy
    ///   - path: The path component where GraphQL should be operated
    ///   - context: HTTP context builder
    ///   - websocketGuard: WebSocket connection guard
    /// - Returns: Middleware for handling GraphQL operation
    public func vaporMiddleware(
        body: HTTPBodyStreamStrategy = .collect, 
        at path: PathComponent = "graphql",
        context: @escaping VaporHTTPContext,
        websocketGuard: @escaping VaporWebSocketGuard = { _, _ in }
    ) -> VaporGraphQLMiddleware {
        VaporGraphQLMiddleware(server: self, path: [path], body: body, context: context, websocketGuard: websocketGuard)
    }

    /// Pioneer GraphQL handlers for Vapor
    /// - Parameters:
    ///   - body: The body streaming strategy
    ///   - path: The path component where GraphQL should be operated
    ///   - context: HTTP context builder
    ///   - websocketContext: WebSocket context builder
    ///   - websocketGuard: WebSocket connection guard
    /// - Returns: Middleware for handling GraphQL operation
    public func vaporMiddleware(
        body: HTTPBodyStreamStrategy = .collect, 
        at path: PathComponent = "graphql",
        context: @escaping VaporHTTPContext,
        websocketContext: @escaping VaporWebSocketContext,
        websocketGuard: @escaping VaporWebSocketGuard = { _, _ in }
    ) -> VaporGraphQLMiddleware {
        VaporGraphQLMiddleware(server: self, path: [path], body: body, context: context, websocketContext: websocketContext, websocketGuard: websocketGuard)
    }

    /// Pioneer GraphQL handlers for Vapor
    /// - Parameters:
    ///   - body: The body streaming strategy
    ///   - path: The path components where GraphQL should be operated
    ///   - context: HTTP context builder
    ///   - websocketGuard: WebSocket connection guard
    /// - Returns: Middleware for handling GraphQL operation
    public func vaporMiddleware(
        body: HTTPBodyStreamStrategy = .collect, 
        at path: [PathComponent],
        context: @escaping VaporHTTPContext,
        websocketGuard: @escaping VaporWebSocketGuard = { _, _ in }
    ) -> VaporGraphQLMiddleware {
        VaporGraphQLMiddleware(server: self, path: path, body: body, context: context, websocketGuard: websocketGuard)
    }

    /// Pioneer GraphQL handlers for Vapor
    /// - Parameters:
    ///   - body: The body streaming strategy
    ///   - path: The path components where GraphQL should be operated
    ///   - context: HTTP context builder
    ///   - websocketContext: WebSocket context builder
    ///   - websocketGuard: WebSocket connection guard
    /// - Returns: Middleware for handling GraphQL operation
    public func vaporMiddleware(
        body: HTTPBodyStreamStrategy = .collect, 
        at path: [PathComponent],
        context: @escaping VaporHTTPContext,
        websocketContext: @escaping VaporWebSocketContext,
        websocketGuard: @escaping VaporWebSocketGuard = { _, _ in }
    ) -> VaporGraphQLMiddleware {
        VaporGraphQLMiddleware(server: self, path: path, body: body, context: context, websocketContext: websocketContext, websocketGuard: websocketGuard)
    }
}