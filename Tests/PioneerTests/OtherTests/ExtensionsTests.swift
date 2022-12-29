//
//  ExtensionsTests.swift
//  Pioneer
//
//  Created by d-exclaimation on 2:16 PM.
//  Copyright © 2021 d-exclaimation. All rights reserved.
//

import Foundation
import enum GraphQL.Map
import NIO
import OrderedCollections
@testable import Pioneer
import Vapor
import XCTest

final class ExtensionsTests: XCTestCase {
    private let app = Application(.testing)

    /// Tester Actor
    private actor Tester {
        enum Act {
            case call(expect: EventLoopFuture<XCTestExpectation>)
            case outcome(expect: XCTestExpectation)
            case none
        }

        func call(expect: Task<XCTestExpectation, Error>) {
            pipeToSelf(future: expect) { sink, res in
                guard case let .success(ex) = res else { return }
                await sink.outcome(expect: ex)
            }
        }

        func outcome(expect: XCTestExpectation) {
            expect.fulfill()
        }
    }

    /// Pipe back Future to an actor
    /// 1. Should not fulfill under 1 second
    /// 2. Should fulfill by the Actor after the delay
    func testActorAndNIOFuture() async {
        let expectation = XCTestExpectation()
        let tester = Tester()
        await tester.call(expect: .init {
            try? await Task.sleep(nanoseconds: 1000 * 1000 * 1000)
            return expectation
        })

        wait(for: [expectation], timeout: 2)
    }

    /// Test Structure
    struct A: Decodable {
        var id: String?
    }

    /// JSON String to Structure
    /// 1. Should be able to parse all fields if given
    /// 2. Should be able to infer Optional if not given
    func testDataJSONDecoder() {
        let json = "{ \"id\": null }"
        guard let res = json.data(using: .utf8)?.to(A.self) else {
            return XCTFail("Un-decodable JSON")
        }
        XCTAssert(res.id == nil)

        let json2 = "{}"
        guard let res2 = json2.data(using: .utf8)?.to(A.self) else {
            return XCTFail("Un-decodable JSON")
        }
        XCTAssert(res2.id == nil)
    }

    /// Dictionary Mutating method operations
    /// 1. Should not call callback if found
    /// 2. Should call callback if not found
    func testDictionaryOperation() {
        var isAllowed = false
        var dict = [String: Int]()
        func produce() -> Int {
            XCTAssert(isAllowed)
            return Int.random()
        }

        dict["a"] = 1
        let a = dict.getOrElse("a", or: produce)
        XCTAssert(a == 1)
        isAllowed.toggle()
        let _ = dict.getOrElse("b", or: produce)
    }

    /// Bridging between two dictionaries
    /// 1. Should remain all key value pairs when converting
    func testOrderedDictionaryCompat() {
        var ordered = OrderedDictionary<String, Int>()
        ordered["1"] = 1
        ordered["2"] = 2

        let unordered = ordered.unordered()
        guard let res1 = unordered["1"], let res2 = unordered["2"] else {
            return XCTFail()
        }
        XCTAssert(res1 == 1 && res2 == 2)
    }

    /// Bridging between websocket context builder with context builder
    /// 1. Should set the headers and query parameters to the request
    /// 2. Should set the graphql request into request body
    func testDefaultWebsocketContextBuilder() async {
        let originalReq = Request(application: app, method: .POST, url: "http://localhost:8080/graphql", on: app.eventLoopGroup.next())
        let connectionParams = [
            "query": Map.string("verified=true"),
            "headers": Map.dictionary([
                "auth": "token",
            ]),
        ]
        let originalGql = GraphQLRequest(query: "query { someField }")
        do {
            let req = try await originalReq.defaultWebsocketContextBuilder(
                payload: connectionParams, gql: originalGql,
                contextBuilder: { req, _ in req }
            )
            guard let verified: String = req.query["verified"] else {
                return XCTFail("No query parameter")
            }
            XCTAssert(verified == "true")
            guard let token = req.headers["auth"].first else {
                return XCTFail("No headers")
            }
            XCTAssert(token == "token")
            guard let gql = try? req.content.decode(GraphQLRequest.self) else {
                return XCTFail("cannot parse body")
            }
            XCTAssert(gql.query == originalGql.query)
        } catch {
            return XCTFail(error.localizedDescription)
        }
    }

    /// Testing path component parsing
    /// - Parsing ignore all query parameters
    /// - Should omit empty components
    /// - Should decode % to its utf-8 characters
    func testPathComponent() {
        let req0 = Request(
            application: app,
            method: .GET,
            url: "/graphql/nested1/nested2",
            on: app.eventLoopGroup.next()
        )
        XCTAssert(req0.pathComponents.elementsEqual(["graphql", "nested1", "nested2"]))

        let req1 = Request(
            application: app,
            method: .GET,
            url: "/graphql/nested1/nested2?query=1234&fake=1245",
            on: app.eventLoopGroup.next()
        )
        XCTAssert(req1.pathComponents.elementsEqual(["graphql", "nested1", "nested2"]))

        let req2 = Request(
            application: app,
            method: .GET,
            url: "/graphql%20nested1%20nested2",
            on: app.eventLoopGroup.next()
        )
        XCTAssert(req2.pathComponents.elementsEqual(["graphql nested1 nested2"]))
    }

    /// Testing path component matching
    /// - Parsing ignore all query parameters
    /// - Should be able to matching with .anything and .catchall
    func testPathMatching() {
        let req0 = Request(
            application: app,
            method: .GET,
            url: "/graphql/nested1/nested2",
            on: app.eventLoopGroup.next()
        )
        XCTAssertFalse(req0.matching(path: ["graphql"]))
        XCTAssert(req0.matching(path: ["graphql", "nested1", "nested2"]))
        XCTAssert(req0.matching(path: ["graphql", "nested1", .anything]))
        XCTAssert(req0.matching(path: ["graphql", .anything, "nested2"]))
        XCTAssert(req0.matching(path: ["graphql", .anything, .anything]))
        XCTAssert(req0.matching(path: ["graphql", .catchall]))
        XCTAssert(req0.matching(path: [.catchall]))

        let req1 = Request(
            application: app,
            method: .GET,
            url: "/graphql/nested1/nested2?query=1234&fake=1245",
            on: app.eventLoopGroup.next()
        )
        XCTAssertFalse(req1.matching(path: ["graphql"]))
        XCTAssert(req1.matching(path: ["graphql", "nested1", .anything]))
        XCTAssert(req1.matching(path: ["graphql", .anything, "nested2"]))
        XCTAssert(req1.matching(path: ["graphql", .anything, .anything]))
        XCTAssert(req1.matching(path: ["graphql", .catchall]))
        XCTAssert(req1.matching(path: [.catchall]))

        let req2 = Request(
            application: app,
            method: .GET,
            url: "/graphql%20nested1%20nested2",
            on: app.eventLoopGroup.next()
        )
        XCTAssert(req2.matching(path: ["graphql nested1 nested2"]))
        XCTAssert(req2.matching(path: [.anything]))
        XCTAssert(req2.matching(path: [.catchall]))
        XCTAssertFalse(req2.matching(path: ["graphql", "nested1", .anything]))
        XCTAssertFalse(req2.matching(path: ["graphql", .anything, "nested2"]))
        XCTAssertFalse(req2.matching(path: ["graphql", .anything, .anything]))
        XCTAssertFalse(req2.matching(path: ["graphql", .catchall]))

        let req3 = Request(
            application: app,
            method: .GET,
            url: "/",
            on: app.eventLoopGroup.next()
        )
        XCTAssert(req3.matching(path: [.catchall]))
        XCTAssertFalse(req3.matching(path: ["graphql", .catchall]))
    }
}
