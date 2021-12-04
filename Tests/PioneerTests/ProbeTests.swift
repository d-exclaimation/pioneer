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
import Desolate
import GraphQL
import Graphiti
@testable import Pioneer

final class ProbeTests: XCTestCase {
    private let app = Application(.testing)

    deinit {
        app.shutdown()
    }

    struct Resolver {
        func test(_: Void, _: NoArguments) -> String { "test" }
        func subscription(_: Void, _: NoArguments) -> EventStream<String> {
            Nozzle.single("hello").toEventStream()
        }
    }
    func setup() throws -> Desolate<Pioneer<Resolver, Void>.Probe> {
        let schema = try Schema<Resolver, Void>.init {
            Query {
                Graphiti.Field("hello", at: Resolver.test)
            }
            Subscription {
                SubscriptionField("simple", as: String.self, atSub: Resolver.subscription)
            }
        }

        return Desolate(of: .init(schema: schema, resolver: Resolver(), proto: SubscriptionTransportWs.self))
    }

    func consumer() -> (Pioneer<Resolver, Void>.Process, TestConsumer)  {
        let req = Request.init(application: app, on: app.eventLoopGroup.next())
        let consumer = TestConsumer.init(group: app.eventLoopGroup.next())
        return (.init(ws: consumer, ctx: (), req: req), consumer)
    }

    func testOutgoing() async throws {
        let (process, consumer) = consumer()
        let probe = try setup()

        let message = GraphQLMessage(id: "1", type: "next", payload: ["data": .null, "errors": .array([])])

        await probe.task(with: .outgoing(oid: "1", process: process, res: message))

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

    func testStatelessRequest() async throws {
        let (process, consumer) = consumer()
        let probe = try setup()

        await probe.task(with: .connect(process: process))
        await probe.task(with: .once(pid: process.id, oid: "2", gql: .init(query: "query { hello }", operationName: nil, variables: nil)))
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
        await probe.task(with: .disconnect(pid: process.id))
    }

    func testInvalidStatelessRequest() async throws {
        let (process, consumer) = consumer()
        let probe = try setup()

        await probe.task(with: .connect(process: process))
        await probe.task(with: .once(pid: process.id, oid: "3", gql: .init(query: "query { idk }", operationName: nil, variables: nil)))
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
        await probe.task(with: .disconnect(pid: process.id))
    }
}
