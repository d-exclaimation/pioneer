//
//  Pioneer+Vapor+Void.swift
//  pioneer
//
//  Created by d-exclaimation on 16:00.
//

import enum Vapor.PathComponent
import enum Vapor.HTTPMethod
import enum Vapor.HTTPBodyStreamStrategy

extension Pioneer {
    /// Pioneer GraphQL handlers for Vapor
    /// - Parameters:
    ///   - body: The body streaming strategy
    ///   - path: The path component where GraphQL should be operated
    ///   - websocketGuard: WebSocket connection guard
    /// - Returns: Middleware for handling GraphQL operation
    public func vaporMiddleware(
        body: HTTPBodyStreamStrategy = .collect, 
        at path: PathComponent = "graphql",
        websocketGuard: @escaping VaporWebSocketGuard = { _, _ in }
    ) -> VaporGraphQLMiddleware where Context == Void {
        VaporGraphQLMiddleware(
            server: self,
            path: [path],
            body: body, 
            context: { _, _ in },
            websocketContext: { _, _, _ in }, 
            websocketGuard: websocketGuard
        )
    }

    /// Pioneer GraphQL handlers for Vapor
    /// - Parameters:
    ///   - body: The body streaming strategy
    ///   - path: The path components where GraphQL should be operated
    ///   - websocketGuard: WebSocket connection guard
    /// - Returns: Middleware for handling GraphQL operation
    public func vaporMiddleware(
        body: HTTPBodyStreamStrategy = .collect, 
        at path: [PathComponent],
        websocketGuard: @escaping VaporWebSocketGuard = { _, _ in }
    ) -> VaporGraphQLMiddleware where Context == Void {
        VaporGraphQLMiddleware(
            server: self,
            path: path,
            body: body,
            context: { _, _ in },
            websocketContext: { _, _, _ in },
            websocketGuard: websocketGuard
        )
    }
}