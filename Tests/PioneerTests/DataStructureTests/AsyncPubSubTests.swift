//
//  AsyncPubSubTests.swift
//  PioneerTests
//
//  Created by d-exclaimation.
//

import Foundation
import GraphQL
@testable import Pioneer
import XCTest

final class AsyncPubSubTests: XCTestCase {
    /// AsyncPubSub getting `AsyncStream` and publishing data
    /// - Should be able to receive data from all AsyncStream with the same trigger
    /// - Should be able to filter published data to only the same type
    /// - Should be able to publish data after the consumers were set up
    func testPublishingAndConsuming() async {
        let pubsub = AsyncPubSub()
        let trigger = "1"

        // Expectations
        let exp0 = XCTestExpectation()
        let exp1 = XCTestExpectation()

        let task = Task {
            let stream = pubsub.asyncStream(Int.self, for: trigger)
            for await each in stream {
                if each == 0 {
                    exp0.fulfill()
                }
                return
            }
        }

        let task1 = Task {
            let stream = pubsub.asyncStream(Int.self, for: trigger)
            for await each in stream {
                if each == 0 {
                    exp1.fulfill()
                }
                return
            }
        }

        try? await Task.sleep(nanoseconds: UInt64?.milliseconds(1))

        // Should be skipped due to type mismatch
        await pubsub.publish(for: trigger, payload: "invalid")

        // Should be received by both and trigger the expectations
        await pubsub.publish(for: trigger, payload: 0)

        wait(for: [exp0, exp1], timeout: 2)

        task.cancel()
        task1.cancel()
    }

    /// AsyncPubSub closing all consumer for a specific trigger
    /// - Should close all consumer with the same trigger
    /// - Should never receive anything from any consumer
    func testClosing() async {
        let pubsub = AsyncPubSub()
        let trigger = "1"
        let exp0 = XCTestExpectation()
        let exp1 = XCTestExpectation()

        let task = Task {
            let stream = pubsub.asyncStream(Bool.self, for: trigger)
            for await _ in stream {
                return
            }
            exp0.fulfill()
        }

        let task1 = Task {
            let stream = pubsub.asyncStream(Bool.self, for: trigger)
            for await _ in stream {
                return
            }
            exp1.fulfill()
        }

        try? await Task.sleep(nanoseconds: 500_000)

        // Closing should prevent any consumer to receive anything from their for await loop
        // then exit the loop and trigger the expectation
        await pubsub.close(for: trigger)

        wait(for: [exp0, exp1], timeout: 2)

        task.cancel()
        task1.cancel()
    }

    func testAsyncStream() async throws {
        // EventStream.async
        let stream1 = EventStream<Int>
            .async { con in
                con.yield(1)
                con.finish()
            }
        for try await each in stream1.sequence {
            XCTAssertEqual(each, 1)
        }

        // AsyncEventStream.async
        let stream2 = AsyncEventStream<Int, AsyncThrowingStream<Int, Error>> { con in
            con.yield(1)
            con.finish()
        }

        for try await each in stream2.sequence {
            XCTAssertEqual(each, 1)
        }
    }
}
