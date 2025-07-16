//
//  Pioneer+Standalone.swift
//  pioneer
//
//  Created by d-exclaimation on 00:02.
//

import class Vapor.Application
import class Vapor.CORSMiddleware
import class Vapor.ErrorMiddleware
import enum Vapor.HTTPBodyStreamStrategy
import enum Vapor.HTTPMethod
import struct Vapor.Middlewares
import enum Vapor.PathComponent

public extension Pioneer {
    /// Create an instance of Vapor server to run Pioneer
    /// - Parameters:
    ///   - middleware: The Vapor Middleware to be used
    ///   - port: Port number for the server
    ///   - host: Hostname for the server
    ///   - env: Environment mode ("development", "production", "testing")
    ///   - cors: CORS Configuration for the standalone server
    internal func vaporServer(
        middleware: VaporGraphQLMiddleware,
        port: Int = 4000,
        host: String = "127.0.0.1",
        env: String = "development",
        cors: CORSMiddleware.Configuration? = nil
    ) async throws {
        let app = try await Application.make(
            .specified(port: port, host: host, env: env)
        )

        defer {
            Task {
                try await app.asyncShutdown()
            }
        }

        app.logger = .init(label: "pioneer-graphql")
        app.middleware.use(middleware)

        if let cors = cors {
            app.middleware.use(CORSMiddleware(configuration: cors), at: .beginning)
        }

        try await app.execute()
    }

    /// Create and run a standalone server with Pioneer
    /// - Parameters:
    ///   - port: Port number for the server
    ///   - host: Hostname for the server
    ///   - env: Environment mode ("development", "production", "testing")
    ///   - path: The path components where GraphQL should be operated
    ///   - body: The body streaming strategy
    ///   - context: HTTP context builder
    ///   - websocketContext: WebSocket context builder
    ///   - websocketGuard: WebSocket connection guard
    ///   - cors: CORS Configuration for the standalone server
    func standaloneServer(
        port: Int = 4000,
        host: String = "127.0.0.1",
        env: String = "development",
        at path: PathComponent = "graphql",
        body: HTTPBodyStreamStrategy = .collect,
        context: @escaping VaporHTTPContext,
        websocketContext: @escaping VaporWebSocketContext,
        websocketGuard: @escaping VaporWebSocketGuard = { _, _ in },
        cors: CORSMiddleware.Configuration? = nil
    ) async throws {
        try await vaporServer(
            middleware: vaporMiddleware(
                body: body,
                at: path,
                context: context,
                websocketContext: websocketContext,
                websocketGuard: websocketGuard
            ),
            port: port,
            host: host,
            env: env,
            cors: cors
        )
    }

    /// Create and run a standalone server with Pioneer
    /// - Parameters:
    ///   - port: Port number for the server
    ///   - host: Hostname for the server
    ///   - env: Environment mode ("development", "production", "testing")
    ///   - path: The path components where GraphQL should be operated
    ///   - body: The body streaming strategy
    ///   - context: HTTP context builder
    ///   - websocketGuard: WebSocket connection guard
    ///   - cors: CORS Configuration for the standalone server
    func standaloneServer(
        port: Int = 4000,
        host: String = "127.0.0.1",
        env: String = "development",
        at path: PathComponent = "graphql",
        body: HTTPBodyStreamStrategy = .collect,
        context: @escaping VaporHTTPContext,
        websocketGuard: @escaping VaporWebSocketGuard = { _, _ in },
        cors: CORSMiddleware.Configuration? = nil
    ) async throws {
        try await vaporServer(
            middleware: vaporMiddleware(
                body: body,
                at: path,
                context: context,
                websocketGuard: websocketGuard
            ),
            port: port,
            host: host,
            env: env,
            cors: cors
        )
    }

    /// Create and run a standalone server with Pioneer
    /// - Parameters:
    ///   - port: Port number for the server
    ///   - host: Hostname for the server
    ///   - env: Environment mode ("development", "production", "testing")
    ///   - path: The path components where GraphQL should be operated
    ///   - body: The body streaming strategy
    ///   - websocketGuard: WebSocket connection guard
    ///   - cors: CORS Configuration for the standalone server
    func standaloneServer(
        port: Int = 4000,
        host: String = "127.0.0.1",
        env: String = "development",
        at path: PathComponent = "graphql",
        body: HTTPBodyStreamStrategy = .collect,
        websocketGuard: @escaping VaporWebSocketGuard = { _, _ in },
        cors: CORSMiddleware.Configuration? = nil
    ) async throws where Context == Void {
        try await vaporServer(
            middleware: vaporMiddleware(
                body: body,
                at: path,
                websocketGuard: websocketGuard
            ),
            port: port,
            host: host,
            env: env,
            cors: cors
        )
    }

    /// Create and run a standalone server with Pioneer
    /// - Parameters:
    ///   - port: Port number for the server
    ///   - host: Hostname for the server
    ///   - env: Environment mode ("development", "production", "testing")
    ///   - path: The path components where GraphQL should be operated
    ///   - body: The body streaming strategy
    ///   - context: HTTP context builder
    ///   - websocketContext: WebSocket context builder
    ///   - websocketGuard: WebSocket connection guard
    ///   - cors: CORS Configuration for the standalone server
    func standaloneServer(
        port: Int = 4000,
        host: String = "127.0.0.1",
        env: String = "development",
        at path: [PathComponent],
        body: HTTPBodyStreamStrategy = .collect,
        context: @escaping VaporHTTPContext,
        websocketContext: @escaping VaporWebSocketContext,
        websocketGuard: @escaping VaporWebSocketGuard = { _, _ in },
        cors: CORSMiddleware.Configuration? = nil
    ) async throws {
        try await vaporServer(
            middleware: vaporMiddleware(
                body: body,
                at: path,
                context: context,
                websocketContext: websocketContext,
                websocketGuard: websocketGuard
            ),
            port: port,
            host: host,
            env: env,
            cors: cors
        )
    }

    /// Create and run a standalone server with Pioneer
    /// - Parameters:
    ///   - port: Port number for the server
    ///   - host: Hostname for the server
    ///   - env: Environment mode ("development", "production", "testing")
    ///   - path: The path components where GraphQL should be operated
    ///   - body: The body streaming strategy
    ///   - context: HTTP context builder
    ///   - websocketGuard: WebSocket connection guard
    ///   - cors: CORS Configuration for the standalone server
    func standaloneServer(
        port: Int = 4000,
        host: String = "127.0.0.1",
        env: String = "development",
        at path: [PathComponent],
        body: HTTPBodyStreamStrategy = .collect,
        context: @escaping VaporHTTPContext,
        websocketGuard: @escaping VaporWebSocketGuard = { _, _ in },
        cors: CORSMiddleware.Configuration? = nil
    ) async throws {
        try await vaporServer(
            middleware: vaporMiddleware(
                body: body,
                at: path,
                context: context,
                websocketGuard: websocketGuard
            ),
            port: port,
            host: host,
            env: env,
            cors: cors
        )
    }

    /// Create and run a standalone server with Pioneer
    /// - Parameters:
    ///   - port: Port number for the server
    ///   - host: Hostname for the server
    ///   - env: Environment mode ("development", "production", "testing")
    ///   - path: The path components where GraphQL should be operated
    ///   - body: The body streaming strategy
    ///   - websocketGuard: WebSocket connection guard
    ///   - cors: CORS Configuration for the standalone server
    func standaloneServer(
        port: Int = 4000,
        host: String = "127.0.0.1",
        env: String = "development",
        at path: [PathComponent],
        body: HTTPBodyStreamStrategy = .collect,
        websocketGuard: @escaping VaporWebSocketGuard = { _, _ in },
        cors: CORSMiddleware.Configuration? = nil
    ) async throws where Context == Void {
        try await vaporServer(
            middleware: vaporMiddleware(
                body: body,
                at: path,
                websocketGuard: websocketGuard
            ),
            port: port,
            host: host,
            env: env,
            cors: cors
        )
    }
}
