//
//  WebSocketProtocolTests.swift
//  Pioneer
//
//  Created by d-exclaimation.
//

import XCTest
@testable import Pioneer

final class WebSocketProtocolTests: XCTestCase {
    func testSubProtocolName() {
        XCTAssertEqual(SubscriptionTransportWs.name, "graphql-ws")
        XCTAssertEqual(GraphQLWs.name, "graphql-transport-ws")
    }

    func testTypenames() {
        // subscriptions-transport-ws
        XCTAssertEqual(SubscriptionTransportWs.next, "data", "subscriptions-transport-ws's `next` isn't GQL_DATA")
        XCTAssertEqual(SubscriptionTransportWs.complete, "complete", "subscriptions-transport-ws's `complete` isn't GQL_COMPLETE")
        XCTAssertEqual(SubscriptionTransportWs.error, "error", "subscriptions-transport-ws's `error` isn't GQL_ERROR")

        // graphql-ws
        XCTAssertEqual(GraphQLWs.next, "next", "graphql-ws's `next` isn't Next")
        XCTAssertEqual(GraphQLWs.complete, "complete", "graphql-ws's `complete` isn't Complete")
        XCTAssertEqual(GraphQLWs.error, "error", "graphql-ws's `error` isn't Error")
    }

    func testKeepAliveMessage() {
        XCTAssert(SubscriptionTransportWs.keepAliveMessage.contains("\"ka\""), "subscriptions-transport-ws's keep alive message isn't GQL_CONNECTION_KEEP_ALIVE")
        XCTAssert(GraphQLWs.keepAliveMessage.contains("\"ping\""), "graphql-ws's keep alive message isn't Ping")
    }
}
