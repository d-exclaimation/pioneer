//
//  HTTPStrategyTests.swift
//  Pioneer
//
//  Created by d-exclaimation on 18:35.
//

import Graphiti
import NIOFoundationCompat
@testable import Pioneer
import Vapor
import XCTest
import XCTVapor

final class HTTPStrategyTests: XCTestCase {
    private let schema: Schema<Resolver, Void> = try! .init {
        Query {
            Field("fetch", at: Resolver.fetch)
        }
        Mutation {
            Field("update", at: Resolver.update) {
                Argument("bool", at: \.bool)
            }
        }
    }

    struct Resolver {
        func fetch(_: Void, _: NoArguments) async -> Bool {
            true
        }

        struct BoolArgs: Codable {
            var bool: Bool
        }

        func update(_: Void, args: BoolArgs) async -> Bool {
            return args.bool
        }
    }

    func testOnlyPost() throws {
        let server = Pioneer(schema: schema, resolver: .init(), httpStrategy: .onlyPost)
        let app = Application(.testing)
        defer {
            app.shutdown()
        }

        app.middleware.use(server.vaporMiddleware())

        try app.testable().test(
            .GET,
            "/graphql?query=\("query { fetch }".addingPercentEncoding(withAllowedCharacters: .alphanumerics)!)"
        ) { res in
            XCTAssertEqual(res.status, .badRequest)
        }

        try app.testable().test(
            .GET,
            "/graphql?query=\("mutation { update(bool: true) }".addingPercentEncoding(withAllowedCharacters: .alphanumerics)!)"
        ) { res in
            XCTAssertEqual(res.status, .badRequest)
        }

        let body0 = ByteBuffer(data: GraphQLRequest(query: "query { fetch }").json!)

        try app.testable().test(
            .POST,
            "/graphql",
            headers: .init([("Content-Type", "application/json"), ("Content-Length", body0.writableBytes.description)]),
            body: body0
        ) { res in
            XCTAssertEqual(res.status, .ok)
        }

        let body1 = ByteBuffer(data: GraphQLRequest(query: "mutation { update(bool: true) }").json!)

        try app.testable().test(
            .POST,
            "/graphql",
            headers: .init([("Content-Type", "application/json"), ("Content-Length", body1.writableBytes.description)]),
            body: body1
        ) { res in
            XCTAssertEqual(res.status, .ok)
        }
    }

    func testOnlyGet() throws {
        let server = Pioneer(schema: schema, resolver: .init(), httpStrategy: .onlyGet)
        let app = Application(.testing)
        defer {
            app.shutdown()
        }

        app.middleware.use(server.vaporMiddleware())

        try app.testable().test(
            .GET,
            "/graphql?query=\("query { fetch }".addingPercentEncoding(withAllowedCharacters: .alphanumerics)!)"
        ) { res in
            XCTAssertEqual(res.status, .ok)
        }

        try app.testable().test(
            .GET,
            "/graphql?query=\("mutation { update(bool: true) }".addingPercentEncoding(withAllowedCharacters: .alphanumerics)!)"
        ) { res in
            XCTAssertEqual(res.status, .ok)
        }

        let body0 = ByteBuffer(data: GraphQLRequest(query: "query { fetch }").json!)

        try app.testable().test(
            .POST,
            "/graphql",
            headers: .init([("Content-Type", "application/json"), ("Content-Length", body0.writableBytes.description)]),
            body: body0
        ) { res in
            XCTAssertEqual(res.status, .badRequest)
        }

        let body1 = ByteBuffer(data: GraphQLRequest(query: "mutation { update(bool: true) }").json!)

        try app.testable().test(
            .POST,
            "/graphql",
            headers: .init([("Content-Type", "application/json"), ("Content-Length", body1.writableBytes.description)]),
            body: body1
        ) { res in
            XCTAssertEqual(res.status, .badRequest)
        }
    }

    func testQueryOnlyGet() throws {
        let server = Pioneer(schema: schema, resolver: .init(), httpStrategy: .queryOnlyGet)
        let app = Application(.testing)
        defer {
            app.shutdown()
        }

        app.middleware.use(server.vaporMiddleware())

        try app.testable().test(
            .GET,
            "/graphql?query=\("query { fetch }".addingPercentEncoding(withAllowedCharacters: .alphanumerics)!)"
        ) { res in
            XCTAssertEqual(res.status, .ok)
        }

        try app.testable().test(
            .GET,
            "/graphql?query=\("mutation { update(bool: true) }".addingPercentEncoding(withAllowedCharacters: .alphanumerics)!)"
        ) { res in
            XCTAssertEqual(res.status, .badRequest)
        }

        let body0 = ByteBuffer(data: GraphQLRequest(query: "query { fetch }").json!)

        try app.testable().test(
            .POST,
            "/graphql",
            headers: .init([("Content-Type", "application/json"), ("Content-Length", body0.writableBytes.description)]),
            body: body0
        ) { res in
            XCTAssertEqual(res.status, .ok)
        }

        let body1 = ByteBuffer(data: GraphQLRequest(query: "mutation { update(bool: true) }").json!)

        try app.testable().test(
            .POST,
            "/graphql",
            headers: .init([("Content-Type", "application/json"), ("Content-Length", body1.writableBytes.description)]),
            body: body1
        ) { res in
            XCTAssertEqual(res.status, .ok)
        }
    }

    func testMutationOnlyPost() throws {
        let server = Pioneer(schema: schema, resolver: .init(), httpStrategy: .mutationOnlyPost)
        let app = Application(.testing)
        defer {
            app.shutdown()
        }

        app.middleware.use(server.vaporMiddleware())

        try app.testable().test(
            .GET,
            "/graphql?query=\("query { fetch }".addingPercentEncoding(withAllowedCharacters: .alphanumerics)!)"
        ) { res in
            XCTAssertEqual(res.status, .ok)
        }

        try app.testable().test(
            .GET,
            "/graphql?query=\("mutation { update(bool: true) }".addingPercentEncoding(withAllowedCharacters: .alphanumerics)!)"
        ) { res in
            XCTAssertEqual(res.status, .ok)
        }

        let body0 = ByteBuffer(data: GraphQLRequest(query: "query { fetch }").json!)

        try app.testable().test(
            .POST,
            "/graphql",
            headers: .init([("Content-Type", "application/json"), ("Content-Length", body0.writableBytes.description)]),
            body: body0
        ) { res in
            XCTAssertEqual(res.status, .badRequest)
        }

        let body1 = ByteBuffer(data: GraphQLRequest(query: "mutation { update(bool: true) }").json!)

        try app.testable().test(
            .POST,
            "/graphql",
            headers: .init([("Content-Type", "application/json"), ("Content-Length", body1.writableBytes.description)]),
            body: body1
        ) { res in
            XCTAssertEqual(res.status, .ok)
        }
    }

    func testSplit() throws {
        let server = Pioneer(schema: schema, resolver: .init(), httpStrategy: .splitQueryAndMutation)
        let app = Application(.testing)
        defer {
            app.shutdown()
        }

        app.middleware.use(server.vaporMiddleware())

        try app.testable().test(
            .GET,
            "/graphql?query=\("query { fetch }".addingPercentEncoding(withAllowedCharacters: .alphanumerics)!)"
        ) { res in
            XCTAssertEqual(res.status, .ok)
        }

        try app.testable().test(
            .GET,
            "/graphql?query=\("mutation { update(bool: true) }".addingPercentEncoding(withAllowedCharacters: .alphanumerics)!)"
        ) { res in
            XCTAssertEqual(res.status, .badRequest)
        }

        let body0 = ByteBuffer(data: GraphQLRequest(query: "query { fetch }").json!)

        try app.testable().test(
            .POST,
            "/graphql",
            headers: .init([("Content-Type", "application/json"), ("Content-Length", body0.writableBytes.description)]),
            body: body0
        ) { res in
            XCTAssertEqual(res.status, .badRequest)
        }

        let body1 = ByteBuffer(data: GraphQLRequest(query: "mutation { update(bool: true) }").json!)

        try app.testable().test(
            .POST,
            "/graphql",
            headers: .init([("Content-Type", "application/json"), ("Content-Length", body1.writableBytes.description)]),
            body: body1
        ) { res in
            XCTAssertEqual(res.status, .ok)
        }
    }

    func testBoth() throws {
        let server = Pioneer(schema: schema, resolver: .init(), httpStrategy: .both)
        let app = Application(.testing)
        defer {
            app.shutdown()
        }

        app.middleware.use(server.vaporMiddleware())

        try app.testable().test(
            .GET,
            "/graphql?query=\("query { fetch }".addingPercentEncoding(withAllowedCharacters: .alphanumerics)!)"
        ) { res in
            XCTAssertEqual(res.status, .ok)
        }

        try app.testable().test(
            .GET,
            "/graphql?query=\("mutation { update(bool: true) }".addingPercentEncoding(withAllowedCharacters: .alphanumerics)!)"
        ) { res in
            XCTAssertEqual(res.status, .ok)
        }

        let body0 = ByteBuffer(data: GraphQLRequest(query: "query { fetch }").json!)

        try app.testable().test(
            .POST,
            "/graphql",
            headers: .init([("Content-Type", "application/json"), ("Content-Length", body0.writableBytes.description)]),
            body: body0
        ) { res in
            XCTAssertEqual(res.status, .ok)
        }

        let body1 = ByteBuffer(data: GraphQLRequest(query: "mutation { update(bool: true) }").json!)

        try app.testable().test(
            .POST,
            "/graphql",
            headers: .init([("Content-Type", "application/json"), ("Content-Length", body1.writableBytes.description)]),
            body: body1
        ) { res in
            XCTAssertEqual(res.status, .ok)
        }
    }

    func testCsrfPrevention() throws {
        let server = Pioneer(schema: schema, resolver: .init(), httpStrategy: .csrfPrevention)
        let app = Application(.testing)
        defer {
            app.shutdown()
        }

        app.middleware.use(server.vaporMiddleware())

        try app.testable().test(
            .GET,
            "/graphql?query=\("query { fetch }".addingPercentEncoding(withAllowedCharacters: .alphanumerics)!)"
        ) { res in
            XCTAssertEqual(res.status, .ok)
        }

        try app.testable().test(
            .GET,
            "/graphql?query=\("query { fetch }".addingPercentEncoding(withAllowedCharacters: .alphanumerics)!)",
            headers: .init([("Content-Type", "text/plain")])
        ) { res in
            XCTAssertEqual(res.status, .badRequest)
        }

        try app.testable().test(
            .GET,
            "/graphql?query=\("query { fetch }".addingPercentEncoding(withAllowedCharacters: .alphanumerics)!)",
            headers: .init([("Content-Type", "text/plain"), ("Apollo-Require-Preflight", "true")])
        ) { res in
            XCTAssertEqual(res.status, .ok)
        }

        try app.testable().test(
            .GET,
            "/graphql?query=\("query Operation { fetch }".addingPercentEncoding(withAllowedCharacters: .alphanumerics)!)&operationName=Operation",
            headers: .init([("Content-Type", "text/plain"), ("X-Apollo-Operation-Name", "Operation")])
        ) { res in
            XCTAssertEqual(res.status, .ok)
        }

        try app.testable().test(
            .GET,
            "/graphql?query=\("mutation { update(bool: true) }".addingPercentEncoding(withAllowedCharacters: .alphanumerics)!)"
        ) { res in
            XCTAssertEqual(res.status, .badRequest)
        }

        let body0 = ByteBuffer(data: GraphQLRequest(query: "query { fetch }").json!)

        try app.testable().test(
            .POST,
            "/graphql",
            headers: .init([("Content-Type", "application/json"), ("Content-Length", body0.writableBytes.description)]),
            body: body0
        ) { res in
            XCTAssertEqual(res.status, .ok)
        }

        let body1 = ByteBuffer(data: GraphQLRequest(query: "mutation { update(bool: true) }").json!)

        try app.testable().test(
            .POST,
            "/graphql",
            headers: .init([("Content-Type", "application/json"), ("Content-Length", body1.writableBytes.description)]),
            body: body1
        ) { res in
            XCTAssertEqual(res.status, .ok)
        }

        try app.testable().test(
            .POST,
            "/graphql",
            headers: .init([("Content-Type", "multipart/form-data"), ("Content-Length", body1.writableBytes.description)]),
            body: body1
        ) { res in
            XCTAssertEqual(res.status, .badRequest)
        }
    }
}
