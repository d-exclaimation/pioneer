//
//  DroneTests.swift
//  Pioneer
//
//  Created by d-exclaimation on 8:10 PM.
//  Copyright © 2021 d-exclaimation. All rights reserved.
//

import Graphiti
import class GraphQL.EventStream
import class NIO.MultiThreadedEventLoopGroup
@testable import Pioneer
import XCTest

final class DroneTests: XCTestCase {
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

    private var group = MultiThreadedEventLoopGroup(numberOfThreads: 4)
    private var schema = try! Schema<Resolver, Void> {
        Query {
            Field("hello", at: Resolver.hello)
        }
        Subscription {
            SubscriptionField("simple", as: String.self, atSub: Resolver.simple)
            SubscriptionField("delayed", as: String.self, atSub: Resolver.delayed)
        }
    }.schema

    override func tearDownWithError() throws {
        try group.syncShutdownGracefully()
    }

    /// Setup a GraphQLSchema, Pioneer drone, and a TestConsumer
    /// - Returns: The configured consumer and drone itself
    func setup() throws -> (TestClient, Pioneer<Resolver, Void>.Drone) {
        let consumer = TestClient()
        let drone: Pioneer<Resolver, Void>.Drone = .init(
            .init(
                id: UUID(),
                io: consumer,
                payload: nil,
                ev: group.next(),
                context: { _, _ in }
            ),
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

        await drone.start(
            for: "1",
            given: .init(query: "subscription { simple }")
        )

        // Get the first message
        let result = await consumer.pull()
        XCTAssert(result.contains("payload") && result.contains("Hello") && result.contains("1"))

        // Get the second message (completion)
        let completion = await consumer.pull()
        XCTAssert(completion.contains("1"))
    }

    /// Outside stopping subscription
    /// 1. working subscription
    /// 2. stopped before messages were received
    /// 3. should not give anything even completion
    func testOutsideStopSubscription() async throws {
        let (consumer, drone) = try setup()
        await drone.start(
            for: "2",
            given: .init(query: "subscription { delayed }")
        )
        // Stop before messages were received
        await drone.stop(for: "2")

        // Should not give anything even completion
        let result = await consumer.pull(until: 0.3)
        XCTAssert(result == nil)
    }

    /// Killable Drone
    /// 1. working subscription
    /// 2. droned kill before messages were received
    /// 3. should not give anything even completion
    func testKillableSubscription() async throws {
        let (consumer, drone) = try setup()
        await drone.start(for: "2", given: .init(query: "subscription { delayed }", operationName: nil, variables: nil))

        // The entire drone is killed before messages were received
        await drone.acid()

        // Should not give anything even completion
        let result = await consumer.pull(until: 0.3)
        XCTAssert(result == nil)
    }
}
