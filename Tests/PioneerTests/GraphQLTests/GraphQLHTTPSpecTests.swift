//
//  GraphQLHTTPSpecTests.swift
//  pioneer
//
//  Created by d-exclaimation on 13:39.
//

import NIOHTTP1
@testable import Pioneer
import XCTest

final class GraphQLHTTPSpecTests: XCTestCase {
    struct MockRequest: GraphQLRequestConvertible, Sendable {
        var json: String? = nil
        var search: [String: String] = .init()
        var headers: HTTPHeaders = .init()
        var method: HTTPMethod = .GET

        func body<T>(_ decodable: T.Type) throws -> T where T: Decodable {
            guard let res = json?.data(using: .utf8) else {
                throw Err(message: "No JSON body")
            }
            return try JSONDecoder().decode(decodable, from: res)
        }

        func searchParams<T>(_ decodable: T.Type, at: String) -> T? where T: Decodable {
            search[at].flatMap {
                if let res = $0 as? T {
                    return res
                }
                return $0.data(using: .utf8)?.to(decodable)
            }
        }

        struct Err: Error {
            var message: String
        }
    }

    /// Test that valid GET request shouldn't violate the spec
    func testValidHttpGet() {
        // Valid GET with query only
        let req = MockRequest(
            search: [
                "query": "query { hello }",
            ],
            method: .GET
        )

        XCTAssertNoThrow(try req.httpGraphQL, "Should not throw any violation")

        // Valid GET with query and variables
        let req2 = MockRequest(
            search: [
                "query": "query($name: String!) { hello(name: $name) }",
                "variables": "{ \"name\": \"World\" }",
            ],
            method: .GET
        )
        XCTAssertNoThrow(try req2.httpGraphQL, "Should not throw any violation")

        // Valid GET with query, variables and operation name
        let req3 = MockRequest(
            search: [
                "query": "query HelloWorld($name: String!) { hello(name: $name) } mutation { ignoreThis }",
                "variables": "{ \"name\": \"World\" }",
                "operationName": "HelloWorld",
            ],
            method: .GET
        )
        XCTAssertNoThrow(try req3.httpGraphQL, "Should not throw any violation")
    }

    /// Test that valid POST request shouldn't violate the spec
    func testValidHttpPost() {
        // Valid POST with query only
        let req = MockRequest(
            json: """
            {
                "query": "query { hello }"
            }
            """,
            headers: [
                HTTPHeaders.Name.contentType.description: "application/json",
            ],
            method: .POST
        )
        XCTAssertNoThrow(try req.httpGraphQL, "Should not throw any violation")

        // Valid POST with query and variables
        let req2 = MockRequest(
            json: """
            {
                "query": "query($name: String!) { hello(name: $name) }",
                "variables": { "name": "World" }
            }
            """,
            headers: [
                HTTPHeaders.Name.contentType.description: "application/json",
            ],
            method: .POST
        )
        XCTAssertNoThrow(try req2.httpGraphQL, "Should not throw any violation")

        // Valid POST with query, variables and operation name
        let req3 = MockRequest(
            json: """
            {
                "query": "query HelloWorld($name: String!) { hello(name: $name) } mutation { ignoreThis }",
                "variables": { "name": "World" },
                "operationName": "HelloWorld"
            }
            """,
            headers: [
                HTTPHeaders.Name.contentType.description: "application/json",
            ],
            method: .POST
        )
        XCTAssertNoThrow(try req3.httpGraphQL, "Should not throw any violation")
    }

    /// Test that invalid GET request should violate the spec
    func testInvalidHttpGet() {
        // Invalid GET without query
        let req = MockRequest(
            search: [:],
            method: .GET
        )
        XCTAssertThrowsError(try req.httpGraphQL, "Should throw violation") { err in
            guard let violation = err as? GraphQLViolation else {
                XCTFail("Should be a GraphQLViolation, \(err.localizedDescription)")
                return
            }
            XCTAssertEqual(
                violation.message,
                GraphQLViolation.missingQuery.message,
                "Should be missing query"
            )
        }
    }

    /// Test that invalid POST request should violate the spec
    func testInvalidPost() {
        // Invalid POST without content type
        let req = MockRequest(
            json: """
            {
                "query": "query { hello }",
                "variables": { "name": "World" },
                "operationName": "HelloWorld"
            }
            """,
            headers: [:],
            method: .POST
        )

        XCTAssertThrowsError(try req.httpGraphQL, "Should throw violation") { err in
            guard let violation = err as? GraphQLViolation else {
                XCTFail("Should be a GraphQLViolation, \(err.localizedDescription)")
                return
            }
            XCTAssertEqual(
                violation.message,
                GraphQLViolation.invalidContentType.message,
                "Should be missing content type"
            )
        }

        // Invalid POST without query
        let req2 = MockRequest(
            json: """
            {
                "variables": { "name": "World" },
                "operationName": "HelloWorld"
            }
            """,
            headers: [
                HTTPHeaders.Name.contentType.description: "application/json",
            ],
            method: .POST
        )
        XCTAssertThrowsError(try req2.httpGraphQL, "Should throw violation") { err in
            guard let violation = err as? GraphQLViolation else {
                XCTFail("Should be a GraphQLViolation, \(err.localizedDescription)")
                return
            }
            XCTAssertEqual(
                violation.message,
                GraphQLViolation.missingQuery.message,
                "Should be missing query"
            )
        }

        // Invalid POST with invalid query type
        let req3 = MockRequest(
            json: """
            {
                "query": 1,
                "variables": { "name": "World" },
                "operationName": "HelloWorld"
            }
            """,
            headers: [
                HTTPHeaders.Name.contentType.description: "application/json",
            ],
            method: .POST
        )
        XCTAssertThrowsError(try req3.httpGraphQL, "Should throw violation") { err in
            guard let violation = err as? GraphQLViolation else {
                XCTFail("Should be a GraphQLViolation, \(err.localizedDescription)")
                return
            }
            XCTAssertEqual(
                violation.message,
                GraphQLViolation.invalidForm.message,
                "Should be invalid query type"
            )
        }

        // Invalid POST with invalid variables type
        let req4 = MockRequest(
            json: """
            {
                "query": "query { hello }",
                "variables": 1,
                "operationName": "HelloWorld"
            }
            """,
            headers: [
                HTTPHeaders.Name.contentType.description: "application/json",
            ],
            method: .POST
        )
        XCTAssertThrowsError(try req4.httpGraphQL, "Should throw violation") { err in
            guard let violation = err as? GraphQLViolation else {
                XCTFail("Should be a GraphQLViolation, \(err.localizedDescription)")
                return
            }
            XCTAssertEqual(
                violation.message,
                GraphQLViolation.invalidForm.message,
                "Should be invalid variables type"
            )
        }

        // Invalid POST with invalid operation name type
        let req5 = MockRequest(
            json: """
            {
                "query": "query { hello }",
                "variables": { "name": "World" },
                "operationName": 1
            }
            """,
            headers: [
                HTTPHeaders.Name.contentType.description: "application/json",
            ],
            method: .POST
        )
        XCTAssertThrowsError(try req5.httpGraphQL, "Should throw violation") { err in
            guard let violation = err as? GraphQLViolation else {
                XCTFail("Should be a GraphQLViolation, \(err.localizedDescription)")
                return
            }
            XCTAssertEqual(
                violation.message,
                GraphQLViolation.invalidForm.message,
                "Should be invalid operation name type"
            )
        }
    }

    /// Test that invalid method should violate the spec
    func testInvalidMethod() {
        // Invalid method PUT
        let req = MockRequest(
            json: """
            {
                "query": "query { hello }",
                "variables": { "name": "World" },
                "operationName": "HelloWorld"
            }
            """,
            headers: [
                HTTPHeaders.Name.contentType.description: "application/json",
            ],
            method: .PUT
        )
        XCTAssertThrowsError(try req.httpGraphQL, "Should throw violation") { err in
            guard let violation = err as? GraphQLViolation else {
                XCTFail("Should be a GraphQLViolation, \(err.localizedDescription)")
                return
            }
            XCTAssertEqual(
                violation.message,
                GraphQLViolation.invalidMethod.message,
                "Should be invalid method"
            )
        }

        // Invalid method DELETE
        let req2 = MockRequest(
            json: """
            {
                "query": "query { hello }",
                "variables": { "name": "World" },
                "operationName": "HelloWorld"
            }
            """,
            headers: [
                HTTPHeaders.Name.contentType.description: "application/json",
            ],
            method: .DELETE
        )
        XCTAssertThrowsError(try req2.httpGraphQL, "Should throw violation") { err in
            guard let violation = err as? GraphQLViolation else {
                XCTFail("Should be a GraphQLViolation, \(err.localizedDescription)")
                return
            }
            XCTAssertEqual(
                violation.message,
                GraphQLViolation.invalidMethod.message,
                "Should be invalid method"
            )
        }

        // Invalid method PATCH
        let req3 = MockRequest(
            json: """
            {
                "query": "query { hello }",
                "variables": { "name": "World" },
                "operationName": "HelloWorld"
            }
            """,
            headers: [
                HTTPHeaders.Name.contentType.description: "application/json",
            ],
            method: .PATCH
        )
        XCTAssertThrowsError(try req3.httpGraphQL, "Should throw violation") { err in
            guard let violation = err as? GraphQLViolation else {
                XCTFail("Should be a GraphQLViolation, \(err.localizedDescription)")
                return
            }
            XCTAssertEqual(
                violation.message,
                GraphQLViolation.invalidMethod.message,
                "Should be invalid method"
            )
        }

        // Invalid method HEAD
        let req4 = MockRequest(
            json: """
            {
                "query": "query { hello }",
                "variables": { "name": "World" },
                "operationName": "HelloWorld"
            }
            """,
            headers: [
                HTTPHeaders.Name.contentType.description: "application/json",
            ],
            method: .HEAD
        )
        XCTAssertThrowsError(try req4.httpGraphQL, "Should throw violation") { err in
            guard let violation = err as? GraphQLViolation else {
                XCTFail("Should be a GraphQLViolation, \(err.localizedDescription)")
                return
            }
            XCTAssertEqual(
                violation.message,
                GraphQLViolation.invalidMethod.message,
                "Should be invalid method"
            )
        }

        // Invalid method OPTIONS
        let req5 = MockRequest(
            json: """
            {
                "query": "query { hello }",
                "variables": { "name": "World" },
                "operationName": "HelloWorld"
            }
            """,
            headers: [
                HTTPHeaders.Name.contentType.description: "application/json",
            ],
            method: .OPTIONS
        )
        XCTAssertThrowsError(try req5.httpGraphQL, "Should throw violation") { err in
            guard let violation = err as? GraphQLViolation else {
                XCTFail("Should be a GraphQLViolation, \(err.localizedDescription)")
                return
            }
            XCTAssertEqual(
                violation.message,
                GraphQLViolation.invalidMethod.message,
                "Should be invalid method"
            )
        }

        // Invalid method TRACE
        let req6 = MockRequest(
            json: """
            {
                "query": "query { hello }",
                "variables": { "name": "World" },
                "operationName": "HelloWorld"
            }
            """,
            headers: [
                HTTPHeaders.Name.contentType.description: "application/json",
            ],
            method: .TRACE
        )
        XCTAssertThrowsError(try req6.httpGraphQL, "Should throw violation") { err in
            guard let violation = err as? GraphQLViolation else {
                XCTFail("Should be a GraphQLViolation, \(err.localizedDescription)")
                return
            }
            XCTAssertEqual(
                violation.message,
                GraphQLViolation.invalidMethod.message,
                "Should be invalid method"
            )
        }

        // Invalid method CONNECT
        let req7 = MockRequest(
            json: """
            {
                "query": "query { hello }",
                "variables": { "name": "World" },
                "operationName": "HelloWorld"
            }
            """,
            headers: [
                HTTPHeaders.Name.contentType.description: "application/json",
            ],
            method: .CONNECT
        )
        XCTAssertThrowsError(try req7.httpGraphQL, "Should throw violation") { err in
            guard let violation = err as? GraphQLViolation else {
                XCTFail("Should be a GraphQLViolation, \(err.localizedDescription)")
                return
            }
            XCTAssertEqual(
                violation.message,
                GraphQLViolation.invalidMethod.message,
                "Should be invalid method"
            )
        }
    }
}
