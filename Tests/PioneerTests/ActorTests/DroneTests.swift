//
//  DroneTests.swift
//  Pioneer
//
//  Created by d-exclaimation on 8:10 PM.
//  Copyright © 2021 d-exclaimation. All rights reserved.
//

import Foundation
import XCTest
import NIOWebSocket
import Vapor
import GraphQL
import Graphiti
@testable import Pioneer

final class DroneTests: XCTestCase {
    private let app = Application(.testing)

    deinit {
        app.shutdown()
    }
    
    /// Simple Test Resolver
    class Resolver {
        /// Unused Query resolver, only here to satisfy Schema
        func hello(_: Void, _: NoArguments) -> String { "Hello World!" }
        
        /// Simple 1 messaage subscriptions
        /// Should:
        ///     - Send Hello and finish the stream
        ///     - Print done when finished
        func simple(_: Void, _: NoArguments) -> EventStream<String> {
            let stream = AsyncStream(String.self) { continuation in
                continuation.yield("Hello")
                continuation.finish()
            }
            return stream.toEventStream(
                onTermination: { _ in
                    print("Done")
                }
            )
        }

        /// Simple 1 message subscriptions with a delay
        /// Should:
        ///     - Send hello after a delay and finish the stream
        ///     - Print done when finished
        func delayed(_: Void, _: NoArguments) -> EventStream<String> {
            let stream = AsyncStream(String.self) { continuation in
                Task.init {
                    try await Task.sleep(nanoseconds: 1000 * 1000 * 250)
                    continuation.yield("Hello")
                    continuation.finish()
                }
            }
            return stream.toEventStream(
                onTermination: { _ in
                    print("Done")
                }
            )
        }
    }
    
    /// Setup a GraphQLSchema, Pioneer drone, and a TestConsumer
    /// - Returns: The configured consumer and drone itself
    func setup() throws -> (TestConsumer, Pioneer<Resolver, Void>.Drone) {
        let schema = try Schema<Resolver, Void>.init {
            Query {
                Field("hello", at: Resolver.hello)
            }
            Subscription {
                SubscriptionField("simple", as: String.self, atSub: Resolver.simple)
                SubscriptionField("delayed", as: String.self, atSub: Resolver.delayed)
            }
        }.schema
        let req = Request.init(application: app, on: app.eventLoopGroup.next())
        let consumer = TestConsumer.init(group: app.eventLoopGroup.next())
        let process = Pioneer<Resolver, Void>.SocketClient(id: UUID(), io: consumer, payload: nil, ev: req.eventLoop, context: { _, _ in })
        let drone: Pioneer<Resolver, Void>.Drone = .init(
            process,
            schema: schema,
            resolver: Resolver(),
            proto: SubscriptionTransportWs.self
        )
        return (consumer, drone)
    }

    /// Best case subscription:
    /// 1. working subscription
    /// 2. get two message: data and completion
    func testBestCaseSubscription() async throws {
        let (consumer, drone) = try setup()

        await drone.start(for: "1", given: .init(query: "subscription { simple }", operationName: nil, variables: nil))

        let result = await consumer.wait()
        XCTAssert(result.contains("payload") && result.contains("Hello") && result.contains("1"))
        let completion = await consumer.wait()
        XCTAssert(completion.contains("1"))
    }

    /// Outside stopping subscription
    /// 1. working subscription
    /// 2. stopped before messages were received
    /// 3. should not give anything even completion
    func testOutsideStopSubscription() async throws {
        let (consumer, drone) = try setup()
        await drone.start(for: "2", given: .init(query: "subscription { delayed }", operationName: nil, variables: nil))
        await drone.stop(for: "2")
        let result = await consumer.waitThrowing(time: 0.3)
        XCTAssert(result == nil)
    }

    /// Killable Drone
    /// 1. working subscription
    /// 2. droned kill before messages were received
    /// 3. should not give anything even completion
    func testKillableSubscription() async throws {
        let (consumer, drone) = try setup()
        await drone.start(for: "2", given: .init(query: "subscription { delayed }", operationName: nil, variables: nil))
        await drone.acid()
        let result = await consumer.waitThrowing(time: 0.3)
        XCTAssert(result == nil)
    }
}
