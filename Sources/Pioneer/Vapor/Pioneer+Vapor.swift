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

    /// Pioneer Integration for Vapor as a Middleware
    public struct VaporGraphQLMiddleware: AsyncMiddleware {
        /// Service to serve by the middleware
        enum Serve {
            /// GraphQL over HTTP operation should be served
            case operation

            /// GraphQL over WebSocket upgrade should be served
            case upgrade

            /// GraphQL IDE should be served
            case playground
            
            /// No service, skip this middleware
            case ignore
        }

        /// Pioneer GraphQL server
        private let server: Pioneer

        /// The path to be served
        private let path: [PathComponent] 

        /// The body stream strategy used
        private let body: HTTPBodyStreamStrategy

        /// HTTP Context Builder
        private let context: VaporHTTPContext

        /// WebSocket Context Builder
        private let websocketContext: VaporWebSocketContext

        /// WebSocket Initialisation Guard
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

        /// Check whether request should be served by Pioneer
        /// - Parameter request: The incoming request
        /// - Returns: True if should be served
        private func shouldServe(to request: Request) -> Bool {
            (request.method == .POST || request.method == .GET) && request.matching(path: path)
        }

        /// What type of service should Pioneer serve for this request
        /// - Parameter request: The incoming request
        /// - Returns: A service to be done
        private func serving(to request: Request) async throws -> Serve {
            if request.method == .POST {
                return .operation
            }

            if server.websocketProtocol.isAccepting && request.isWebSocketUpgrade {
                return .upgrade
            }

            if case .some = request.query[String.self, at: "query"] {
                return .operation
            }

            return server.playground == .disable ? .ignore : .playground
        }

        /// Collect the body to avoid issue with asynchronous body collection if strategy is `.collect`
        /// - Parameter request: The incoming request
        /// - Returns: The request after the body is collected if necessary
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
            guard shouldServe(to: request) else {
                return try await next.respond(to: request)
            }

            switch try await serving(to: request) {
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