//
//  Pioneer+Vapor.swift
//  pioneer
//
//  Created by d-exclaimation on 09:44.
//

import protocol Vapor.AsyncMiddleware
import class Vapor.Request
import class Vapor.Response
import class Vapor.Route
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

        internal init(server: Pioneer, path: [PathComponent], body: HTTPBodyStreamStrategy) {
            self.server = server
            self.path = path
            self.body = body
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
                    return try await server.httpHandler(req: collect(request))
                case .upgrade:
                    return try await server.webSocketHandler(req: collect(request))
                case .playground:
                    return server.ideHandler(req: request)
                case .ignore:
                    return try await next.respond(to: request)
            }
        }
    }
    
    /// Pioneer GraphQL handlers for Vapor
    /// - Returns: Middleware to handle GraphQL specific request
    public func vaporMiddleware(body: HTTPBodyStreamStrategy = .collect) -> VaporGraphQLMiddleware {
        vaporMiddleware(body: body, at: "graphql")
    }

    /// Pioneer GraphQL handlers for Vapor
    /// - Parameters:
    ///   - path: The path within the route to add handles
    /// - Returns: Middleware to handle GraphQL specific request
    public func vaporMiddleware(body: HTTPBodyStreamStrategy = .collect, at path: PathComponent...) -> VaporGraphQLMiddleware {
        VaporGraphQLMiddleware(server: self, path: path, body: body)
    }
}