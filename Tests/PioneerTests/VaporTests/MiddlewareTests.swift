import enum GraphQL.Map
@testable import Pioneer
import Vapor
import XCTest

final class MiddlewareTests: XCTestCase {
    private let app = Application(.testing)

    /// Bridging between websocket context builder with context builder
    /// 1. Should set the headers and query parameters to the request
    /// 2. Should set the graphql request into request body
    func testDefaultWebsocketContextBuilder() async {
        let originalReq = Request(
            application: app,
            method: .POST,
            url: "http://localhost:8080/graphql",
            on: app.eventLoopGroup.next()
        )
        let payload = [
            "query": Map.string("verified=true"),
            "headers": Map.dictionary([
                "auth": "token",
            ]),
        ]

        let originalGql = GraphQLRequest(query: "query { someField }")
        do {
            let req = try await originalReq.defaultWebsocketContextBuilder(
                payload: payload, gql: originalGql,
                contextBuilder: { req, _ in req }
            )

            // 1. Should set the headers
            guard let token = req.headers["auth"].first else {
                return XCTFail("No headers")
            }
            XCTAssert(token == "token")
            // and query parameters to the request
            guard let verified: String = req.query["verified"] else {
                return XCTFail("No query parameter")
            }
            XCTAssert(verified == "true")

            // 2. Should set the graphql request into request body
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

        // - Parsing ignore all query parameters
        let req1 = Request(
            application: app,
            method: .GET,
            url: "/graphql/nested1/nested2?query=1234&fake=1245",
            on: app.eventLoopGroup.next()
        )
        XCTAssert(req1.pathComponents.elementsEqual(["graphql", "nested1", "nested2"]))

        // - Should decode % to its utf-8 characters
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

        // - Parsing ignore all query parameters
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

        // - Should be able to matching with .anything and .catchall
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
