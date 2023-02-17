//
//  ContextTests.swift
//  Pioneer
//
//  Created by d-exclaimation on 18:06.
//

import Graphiti
import Vapor
import XCTest
import XCTVapor
@testable import Pioneer

final class ContextTests: XCTestCase {
    private let server = Pioneer(
        schema: try! Schema<Resolver, Context> {
            ID.asScalar()

            Query {
                Field("test", at: Resolver.test)
            }
        },
        resolver: .init(),
        httpStrategy: .both,
        introspection: true
    )

    struct Context {
        var auth: String
        var res: Response
    }

    struct Resolver {
        func test(ctx: Context, _: NoArguments) async -> ID {
            ctx.res.headers.add(name: .authorization, value: "Bearer \(ctx.auth)")
            return ctx.auth.id
        }
    }

    /// Context Builder:
    /// - Should get the proper context given the right headers
    /// - Should rethrow error from the context builder
    func testContextBuilderThrowing() throws {
        let app = Application(.testing)
        defer {
            app.shutdown()
        }

        // Construct context for each request
        app.middleware.use(
            server.vaporMiddleware(
                at: "graphql",
                context: { req, res in
                    guard let authorization = req.headers[.authorization].first else {
                        throw Abort(.unauthorized, reason: "Cannot authoriza user")
                    }
                    guard authorization.contains("Bearer "), let token = authorization.split(separator: " ").last?.description else {
                        throw Abort(.unauthorized, reason: "Cannot authoriza user")
                    }
                    return Context(auth: token, res: res)
                }
            )
        )

        // Was able to get the context and the auth header
        try app.testable().test(
            .GET,
            "/graphql?query=\("query { test }".addingPercentEncoding(withAllowedCharacters: .alphanumerics)!)",
            headers: .init([("Authorization", "Bearer Hello")])
        ) { res in
            XCTAssertEqual(res.status, .ok)
            XCTAssertEqual(res.headers[.authorization].first, .some("Bearer Hello"))
            XCTAssert(res.body.string.contains("Hello"))
        }

        // Was not able to get the context and the auth header
        try app.testable().test(
            .GET,
            "/graphql?query=\("query { test }".addingPercentEncoding(withAllowedCharacters: .alphanumerics)!)"
        ) { res in
            XCTAssertEqual(res.status, .unauthorized)
        }
    }
}
