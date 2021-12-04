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
import Desolate
import Graphiti
@testable import Pioneer

final class DroneTests: XCTestCase {
    private let app = Application(.testing)

    class Resolver {
        func hello(_: Void, _: NoArguments) -> String { "Hello World!" }
        func simple(_: Void, _: NoArguments) -> EventStream<String> {
            let stream = AsyncStream(String.self) { continuation in
                continuation.yield("Hello")
                continuation.finish()
            }
            return stream.toEventStream(
                onTermination: {
                    print("Done")
                }
            )
        }

        func delayed(_: Void, _: NoArguments) -> EventStream<String> {
            let stream = AsyncStream(String.self) { continuation in
                Task.init {
                    await Task.sleep(1000 * 1000 * 250)
                    continuation.yield("Hello")
                    continuation.finish()
                }
            }
            return stream.toEventStream(
                onTermination: {
                    print("Done")
                }
            )
        }
    }

    struct TestConsumer: ProcessingConsumer {
        var buffer: Buffer = .init()
        var group: EventLoopGroup
        actor Buffer {
            var store: [String] = []

            func set(_ s: String) {
                store.append(s)
            }

            func pop() -> String? {
                guard !store.isEmpty else { return nil }
                return store.removeFirst()
            }
        }
        func send<S>(msg: S) where S: Collection, S.Element == Character {
            guard let str = msg as? String else { return }
            Task.init {
                await buffer.set(str)
            }
        }

        func close(code: WebSocketErrorCode) -> EventLoopFuture<Void> {
            group.next().makeSucceededVoidFuture()
        }

        func wait() async -> String {
            await withCheckedContinuation { continuation in
                Task.init {
                    while true {
                        if let res = await buffer.pop() {
                            continuation.resume(returning: res)
                            return
                        }
                        await Task.requeue()
                    }
                }
            }
        }

        func waitThrowing(time: TimeInterval) async -> String? {
            let start = Date()
            var res = Optional<String>.none
            while abs(start.timeIntervalSinceNow) < time {
                res = await buffer.pop()
            }
            return res
        }
    }

    func setup() throws -> (TestConsumer, Desolate<Pioneer<Resolver, Void>.Drone>) {
        let schema = try Schema<Resolver, Void>.init {
            Query {
                Field("hello", at: Resolver.hello)
            }
            Subscription {
                SubscriptionField("simple", as: String.self, atSub: Resolver.simple)
                SubscriptionField("delayed", as: String.self, atSub: Resolver.delayed)
            }
        }
        let req = Request.init(application: app, on: app.eventLoopGroup.next())
        let consumer = TestConsumer.init(group: app.eventLoopGroup.next())
        let process = Pioneer<Resolver, Void>.Process(ws: consumer, ctx: (), req: req)
        let drone = Desolate(of: Pioneer.Drone(process, schema: schema, resolver: Resolver(), proto: SubscriptionTransportWs.self))
        return (consumer, drone)
    }

    func testBestCaseSubscription() async throws {
        let (consumer, drone) = try setup()

        await drone.task(with: .start(oid: "1", gql: .init(query: "subscription { simple }", operationName: nil, variables: nil)))

        let result = await consumer.wait()
        XCTAssert(result.contains("payload") && result.contains("Hello") && result.contains("1"))
        let completion = await consumer.wait()
        XCTAssert(completion.contains("1"))
    }

    func testOutsideStopSubscription() async throws {
        let (consumer, drone) = try setup()
        await drone.task(with: .start(oid: "2", gql: .init(query: "subscription { delayed }", operationName: nil, variables: nil)))
        await drone.task(with: .stop(oid: "2"))
        let result = await consumer.waitThrowing(time: 0.3)
        XCTAssert(result == nil)
    }

    func testKillableSubscription() async throws {
        let (consumer, drone) = try setup()
        await drone.task(with: .start(oid: "2", gql: .init(query: "subscription { delayed }", operationName: nil, variables: nil)))
        await drone.task(with: .acid)
        let result = await consumer.waitThrowing(time: 0.3)
        XCTAssert(result == nil)
    }
}
