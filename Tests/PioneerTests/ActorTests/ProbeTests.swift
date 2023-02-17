//
//  ProbeTests.swift
//  Pioneer
//
//  Created by d-exclaimation on 9:01 PM.
//  Copyright © 2021 d-exclaimation. All rights reserved.
//

import Graphiti
import XCTest
import class GraphQL.EventStream
import class NIO.MultiThreadedEventLoopGroup
@testable import Pioneer

final class ProbeTests: XCTestCase {
    /// Simple resolver with a single subscriptions
    struct Resolver {
        func test(_: Void, _: NoArguments) -> String { "test" }
        func subscription(_: Void, _: NoArguments) -> EventStream<String> {
            AsyncStream.just("hello").toEventStream()
        }
    }

    private let group = MultiThreadedEventLoopGroup(numberOfThreads: 4)
    private let schema = try! Schema<Resolver, Void>.init {
        Query {
            Graphiti.Field("hello", at: Resolver.test)
        }
        Subscription {
            SubscriptionField("simple", as: String.self, atSub: Resolver.subscription)
        }
    }.schema
    
    override func tearDownWithError() throws {
        try group.syncShutdownGracefully()
    }

    /// Setup the GraphQL schema and Probe, then return the Probe
    func setup() -> Pioneer<Resolver, Void>.Probe {
        return .init(
            schema: schema,
            resolver: Resolver(),
            proto: GraphQLWs.self
        )
    }

    /// Setup a Process using a custom test consumer
    func consumer() -> (Pioneer<Resolver, Void>.WebSocketClient, TestConsumer) {
        let consumer = TestConsumer()
        return (
            .init(
                id: UUID(),
                io: consumer,
                payload: [:],
                ev: group.next(),
                context: { _, _ in }
            ),
            consumer
        )
    }

    /// Probe
    /// 1. Should be able to dispatch message given a `outgoing` message
    /// 2. The result should be in a JSON string format
    func testOutgoing() async throws {
        let (process, con) = consumer()
        let probe = setup()

        // Outgoing message should pass through
        let message = GraphQLMessage(id: "1", type: "next", payload: ["data": .null, "errors": .array([])])
        await probe.outgoing(with: "1", to: process, given: message)

        // Should receive the message and the completion
        let results = await con.waitAllWithValue(requirement: 2)
        guard let _ = results.first(where: { $0.contains("\"complete\"") && $0.contains("\"1\"") }) else {
            return XCTFail("No completion")
        }
        guard let res = results.first(where: { $0.contains("\"next\"") }) else {
            return XCTFail("No result")
        }
        XCTAssert(res.contains("\"1\""))
        XCTAssert(res.contains("{") && res.contains("}"))
        XCTAssert(res.contains("\"payload\":"))
        XCTAssert(res.contains("\"data\":null"))
    }

    /// Probe
    /// 1. Should accept `once` message
    /// 2. Should execute operation and pipe back the future
    /// 3. Should receive the future as `outgoing` message
    /// 4. Should dispatch result into consumer as JSON string
    func testStatelessRequest() async throws {
        let (process, consumer) = consumer()
        let probe = setup()

        // Connect first
        await probe.connect(with: process)

        // Send a stateless request
        await probe.once(for: process.id, with: "2", given: .init(query: "query { hello }", operationName: nil, variables: nil))

        // Should receive the message and the completion
        let results = await consumer.waitAllWithValue(requirement: 2)
        guard let _ = results.first(where: { $0.contains("\"complete\"") && $0.contains("\"2\"") }) else {
            return XCTFail("No completion")
        }
        guard let res = results.first(where: { $0.contains("\"data\"") }) else {
            return XCTFail("No result")
        }
        XCTAssert(res.contains("\"2\""))
        XCTAssert(res.contains("{") && res.contains("}"))
        XCTAssert(res.contains("\"payload\":"))
        XCTAssert(res.contains("\"data\":"))
        XCTAssert(res.contains("\"hello\":\"test\""))
        XCTAssert(res.contains("\"test\""))

        // Check if the message contains the correct data
        guard let message = res.data(using: .utf8)?.to(GraphQLMessage.self) else {
            return XCTFail("Unparseable data")
        }
        guard let data = message.payload?["data"]?.jsonString else {
            return XCTFail("No payload")
        }

        XCTAssert(data.contains("\"hello\":\"test\""))
        await probe.disconnect(for: process.id)
    }

    /// Probe
    /// 1. Should still accept `once` message
    /// 2. Should execute faulty operation and pipe back the future
    /// 3. Should still receive the future as `outgoing` message
    /// 4. Should dispatch result into consumer as JSON string but with no `data` and instead an `errors` array.
    func testInvalidStatelessRequest() async throws {
        let (process, consumer) = consumer()
        let probe = setup()

        // Connect first
        await probe.connect(with: process)

        // Send a stateless request (but expect an error)
        await probe.once(for: process.id, with: "3", given: .init(query: "query { idk }", operationName: nil, variables: nil))

        // Should receive the message and the completion
        let results = await consumer.waitAllWithValue(requirement: 2)
        guard let _ = results.first(where: { $0.contains("\"complete\"") && $0.contains("\"3\"") }) else {
            return XCTFail("No completion")
        }
        guard let res = results.first(where: { $0.contains("\"errors\"") }) else {
            return XCTFail("No result")
        }
        XCTAssert(res.contains("3"))

        // Check if the message contains the correct errors
        guard let message = res.data(using: .utf8)?.to(GraphQLMessage.self) else {
            return XCTFail("Unparseable data")
        }
        guard let payload = message.payload, case let .array(errors) = payload["errors"] else {
            return XCTFail("No payload")
        }
        XCTAssert(!errors.isEmpty)
        await probe.disconnect(for: process.id)
    }
}
