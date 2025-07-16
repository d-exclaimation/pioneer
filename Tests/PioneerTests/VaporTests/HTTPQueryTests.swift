//
//  HTTPQueryTests.swift
//  Pioneer
//
//  Created by d-exclaimation on 15:56.
//

import Graphiti
import NIOFoundationCompat
@testable import Pioneer
import Vapor
import XCTest
import XCTVapor

final class HTTPQueryTests: XCTestCase {
    private let server = Pioneer(
        schema: try! Schema<Resolver, Void> {
            ID.asScalar()

            Type(User.self) {
                Field("id", at: \.id)
                Field("name", at: \.name)
            }

            Query {
                Field("randomUsers", at: Resolver.randomUsers) {
                    Argument("limit", at: \.limit)
                        .defaultValue(1)
                }

                Field("error", at: Resolver.error)
            }
        },
        resolver: .init(),
        httpStrategy: .both,
        introspection: true
    )

    struct User: Codable {
        var id: ID
        var name: String
    }

    struct Resolver {
        struct LimitArgs: Codable {
            var limit: Int
        }

        func randomUsers(_: Void, args: LimitArgs) async -> [User] {
            (0 ..< args.limit).map { i in
                User(id: .init("\(i)"), name: "U\(i)")
            }
        }

        func error(_: Void, _: NoArguments) async throws -> User? {
            throw Abort(.imATeapot, reason: "Expected")
        }
    }

    /// Pioneer when responding to POST request:
    /// - Should respond with proper data when given the proper query
    /// - Should respond with proper data when given query with variables and operation name
    /// - Should respond with proper data when given queries and operation name
    /// - Should respond with proper data and error when given query that resolve in errors
    /// - Should respond with proper error when given invalid query
    /// - Should respond with proper error and status code if given invalid request
    func testOnPost() async throws {
        let gql0 = GraphQLRequest(query: "query { randomUsers(limit: 3) { id, name } }")
        let gql1 = GraphQLRequest(
            query: "query Valid($limit: Int!) { randomUsers(limit: $limit) { id, name } }",
            operationName: "Valid",
            variables: ["limit": .number(.init(1))]
        )
        let gql2 = GraphQLRequest(
            query: "query Invalid { randomUsers { name } } query Valid { randomUsers(limit: 2) { id, name } }",
            operationName: "Valid"
        )
        let gql3 = GraphQLRequest(query: "query { error { id, name } }")
        let gql4 = GraphQLRequest(query: "query { invalid }")

        let app = try await Application.make(.testing)
        defer {
            Task{
                try await app.asyncShutdown()
            }
        }

        app.middleware.use(server.vaporMiddleware(), at: .beginning)

        // Test for valid query and the proper data
        let body0 = ByteBuffer(data: gql0.json ?? .init())
        try await app.testable().test(
            .POST, "/graphql",
            headers: .init([("Content-Type", "application/json"), ("Content-Length", body0.readableBytes.description)]),
            body: body0
        ) { res async throws in
            XCTAssertEqual(res.status, .ok)
            XCTAssert(res.body.string.contains(#"{"data":{"randomUsers":"#))
            XCTAssertFalse(res.body.string.contains(#""errors":"#))
            for i in 0 ..< 3 {
                XCTAssert(res.body.string.contains("\"id\":\"\(i)\""))
                XCTAssert(res.body.string.contains("\"name\":\"U\(i)\""))
            }
        }

        // Test for valid query with variables and operation name
        let body1 = ByteBuffer(data: gql1.json ?? .init())
        try await app.testable().test(
            .POST, "/graphql",
            headers: .init([("Content-Type", "application/json"), ("Content-Length", body1.readableBytes.description)]),
            body: body1
        ) { res async throws in
            XCTAssertEqual(res.status, .ok)
            XCTAssert(res.body.string.contains(#"{"data":{"randomUsers":"#))
            XCTAssertFalse(res.body.string.contains(#""errors":"#))
            for i in 0 ..< 1 {
                XCTAssert(res.body.string.contains("\"id\":\"\(i)\""))
                XCTAssert(res.body.string.contains("\"name\":\"U\(i)\""))
            }
        }

        // Test for valid query with multiple queries and operation name
        let body2 = ByteBuffer(data: gql2.json ?? .init())
        try await app.testable().test(
            .POST, "/graphql",
            headers: .init([("Content-Type", "application/json"), ("Content-Length", body2.readableBytes.description)]),
            body: body2
        ) { res async throws in
            XCTAssertEqual(res.status, .ok)
            XCTAssert(res.body.string.contains(#"{"data":{"randomUsers":"#))
            XCTAssertFalse(res.body.string.contains(#""errors":"#))
            for i in 0 ..< 2 {
                XCTAssert(res.body.string.contains("\"id\":\"\(i)\""))
                XCTAssert(res.body.string.contains("\"name\":\"U\(i)\""))
            }
        }

        // Test for valid query with errors
        let body3 = ByteBuffer(data: gql3.json ?? .init())
        try await app.testable().test(
            .POST, "/graphql",
            headers: .init([("Content-Type", "application/json"), ("Content-Length", body3.readableBytes.description)]),
            body: body3
        ) { res async throws in
            XCTAssertEqual(res.status, .ok)
            XCTAssert(res.body.string.contains(#""data":{"error":null}"#))
            XCTAssert(res.body.string.contains(#""errors":"#))
            XCTAssert(res.body.string.contains("\(Abort(.imATeapot, reason: "Expected"))"))
        }

        // TODO: Move to a separate test as related to GraphQL over HTTP spec
        // Test for invalid query
        let body4 = ByteBuffer(data: gql4.json ?? .init())
        try await app.testable().test(
            .POST, "/graphql",
            headers: .init([("Content-Type", "application/json"), ("Content-Length", body4.readableBytes.description)]),
            body: body4
        ) { res async throws in
            XCTAssertEqual(res.status, .ok)
            XCTAssert(res.body.string.contains(#"{"errors":"#))
        }

        // Test for invalid request (no body)
        try await app.testable().test(.POST, "/graphql") { res async throws in
            XCTAssertEqual(res.status, .badRequest)
        }
    }

    /// Pioneer when responding to GET request:
    /// - Should respond with proper data when given the proper query
    /// - Should respond with proper data when given query with variables and operation name
    /// - Should respond with proper data when given queries and operation name
    /// - Should respond with proper data and error when given query that resolve in errors
    /// - Should respond with proper error when given invalid query
    /// - Should respond with proper error and status code if given invalid request
    func testOnGet() async throws {
        let gql0 = "query=" + "query { randomUsers(limit: 3) { id, name } }".addingPercentEncoding(withAllowedCharacters: .alphanumerics)!
        let gql1 = "query=" + "query Valid($limit: Int!) { randomUsers(limit: $limit) { id, name } }".addingPercentEncoding(withAllowedCharacters: .alphanumerics)!
            + "&operationName=Valid"
            + "&variables=" + "{\"limit\":1}".addingPercentEncoding(withAllowedCharacters: .alphanumerics)!
        let gql2 = "query=" + "query Invalid { randomUsers { name } } query Valid { randomUsers(limit: 2) { id, name } }".addingPercentEncoding(withAllowedCharacters: .alphanumerics)!
            + "&operationName=Valid"
        let gql3 = "query=" + "query { error { id, name } }".addingPercentEncoding(withAllowedCharacters: .alphanumerics)!
        let gql4 = "query=" + "query { invalid }".addingPercentEncoding(withAllowedCharacters: .alphanumerics)!

        let app = try await Application.make(.testing)
        defer {
            Task{
                try await app.asyncShutdown()
            }
        }

        app.middleware.use(server.vaporMiddleware(), at: .beginning)

        // Test for valid query
        try await app.testable().test(
            .GET, "/graphql?\(gql0)"
        ) { res async throws in
            XCTAssertEqual(res.status, .ok)
            XCTAssert(res.body.string.contains(#"{"data":{"randomUsers":"#))
            XCTAssertFalse(res.body.string.contains(#""errors":"#))
            for i in 0 ..< 3 {
                XCTAssert(res.body.string.contains("\"id\":\"\(i)\""))
                XCTAssert(res.body.string.contains("\"name\":\"U\(i)\""))
            }
        }

        // Test for valid query with variables and operation name
        try await app.testable().test(
            .GET, "/graphql?\(gql1)"
        ) { res async throws in
            XCTAssertEqual(res.status, .ok)
            XCTAssert(res.body.string.contains(#"{"data":{"randomUsers":"#))
            XCTAssertFalse(res.body.string.contains(#""errors":"#))
            for i in 0 ..< 1 {
                XCTAssert(res.body.string.contains("\"id\":\"\(i)\""))
                XCTAssert(res.body.string.contains("\"name\":\"U\(i)\""))
            }
        }

        // Test for valid query with multiple queries and operation name
        try await app.testable().test(
            .GET, "/graphql?\(gql2)"
        ) { res async throws in
            XCTAssertEqual(res.status, .ok)
            XCTAssert(res.body.string.contains(#"{"data":{"randomUsers":"#))
            XCTAssertFalse(res.body.string.contains(#""errors":"#))
            for i in 0 ..< 2 {
                XCTAssert(res.body.string.contains("\"id\":\"\(i)\""))
                XCTAssert(res.body.string.contains("\"name\":\"U\(i)\""))
            }
        }

        // Test for valid query with errors
        try await app.testable().test(
            .GET, "/graphql?\(gql3)"
        ) { res async throws in
            XCTAssertEqual(res.status, .ok)
            XCTAssert(res.body.string.contains(#""data":{"error":null}"#))
            XCTAssert(res.body.string.contains(#""errors":"#))
            XCTAssert(res.body.string.contains("\(Abort(.imATeapot, reason: "Expected"))"))
        }

        // TODO: Move to a separate test as related to GraphQL over HTTP spec
        // Test for invalid query
        try await app.testable().test(
            .GET, "/graphql?\(gql4)"
        ) { res async throws in
            XCTAssertEqual(res.status, .ok)
            XCTAssert(res.body.string.contains(#"{"errors":"#))
        }

        // Test for playground query
        try await app.testable().test(
            .GET, "/graphql"
        ) { res async throws in
            XCTAssertEqual(res.status, .ok)
        }

        // Test for invalid route
        try await app.testable().test(
            .GET, "/graphql/wrong"
        ) { res async throws in
            XCTAssertEqual(res.status, .notFound)
        }
    }
}
