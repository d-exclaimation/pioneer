//
//  ProbeTests.swift
//  Pioneer
//
//  Created by d-exclaimation on 9:01 PM.
//  Copyright © 2021 d-exclaimation. All rights reserved.
//

import Foundation
import XCTest
import Vapor
import GraphQL
import Graphiti
@testable import Pioneer

final class ProbeTests: XCTestCase {
    private let app = Application(.testing)

    deinit {
        app.shutdown()
    }

    /// Simple resolver with a single subscriptions
    struct Resolver {
        func test(_: Void, _: NoArguments) -> String { "test" }
        func subscription(_: Void, _: NoArguments) -> EventStream<String> {
            AsyncStream.just("hello").toEventStream()
        }
    }
    
    /// Setup the GraphQL schema and Probe, then return the Probe
    func setup() throws -> Pioneer<Resolver, Void>.Probe {
        let schema = try Schema<Resolver, Void>.init {
            Query {
                Graphiti.Field("hello", at: Resolver.test)
            }
            Subscription {
                SubscriptionField("simple", as: String.self, atSub: Resolver.subscription)
            }
        }.schema

        return .init(schema: schema, resolver: Resolver(), proto: SubscriptionTransportWs.self)
    }

    /// Setup a Process using a custom test consumer
    func consumer() -> (Pioneer<Resolver, Void>.Process, TestConsumer)  {
        let req = Request.init(application: app, on: app.eventLoopGroup.next())
        let consumer = TestConsumer.init(group: app.eventLoopGroup.next())
        return (.init(ws: consumer, ctx: (), req: req), consumer)
    }

    /// Probe
    /// 1. Should be able to dispatch message given a `outgoing` message
    /// 2. The result should be in a JSON string format
    func testOutgoing() async throws {
        let (process, consumer) = consumer()
        let probe = try setup()

        let message = GraphQLMessage(id: "1", type: "next", payload: ["data": .null, "errors": .array([])])

        await probe.outgoing(with: "1", to: process, given: message)

        let results = await consumer.waitAll()
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
        let probe = try setup()

        await probe.connect(with: process)
        await probe.once(for: process.id, with: "2", given: .init(query: "query { hello }", operationName: nil, variables: nil))
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
        let probe = try setup()

        await probe.connect(with: process)
        await probe.once(for: process.id, with: "3", given: .init(query: "query { idk }", operationName: nil, variables: nil))
        let results = await consumer.waitAllWithValue(requirement: 2)
        guard let _ = results.first(where: { $0.contains("\"complete\"") && $0.contains("\"3\"") }) else {
            return XCTFail("No completion")
        }
        guard let res = results.first(where: { $0.contains("\"errors\"") }) else {
            return XCTFail("No result")
        }
        XCTAssert(res.contains("3"))
        guard let message = res.data(using: .utf8)?.to(GraphQLMessage.self) else {
            return XCTFail("Unparseable data")
        }
        guard let payload = message.payload, case .array(let errors) = payload["errors"] else {
            return XCTFail("No payload")
        }
        XCTAssert(!errors.isEmpty)
        await probe.disconnect(for: process.id)
    }
}
