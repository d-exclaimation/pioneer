//
//  GraphitiAsyncEventStreamTests.swift
//  Pioneer
//
//  Created by d-exclaimation on 7:17 PM.
//  Copyright © 2021 d-exclaimation. All rights reserved.
//

import Foundation
import XCTest
import Graphiti
import NIO
import Desolate
@testable import Pioneer

struct Message: Codable, Identifiable {
    var id: String = UUID().uuidString
    var content: String

    struct Arg: Codable {
        var formatting: String
    }

    func description(context: TestContext, arguments: Arg) async throws -> String {
        switch arguments.formatting.lowercased() {
        case "inline":
            return "msg(\(id)): \(content)"
        default:
            return """
            Message:
            id -> \(id)
            > \(content)
            """
        }
    }
}

struct TestContext {}

struct TestResolver {
    let (jet, engine) = Source<Message>.desolate()

    func hello(context: TestContext, arguments: NoArguments) -> String {
        "Hello GraphQL!!"
    }

    struct Arg1: Codable {
        var string: String
    }

    func randomMessage(context: TestContext, arguments: Arg1) async throws -> Message {
        let message = Message(content: arguments.string)
        engine.tell(with: .next(message))
        return message
    }

    func onMessage(context: TestContext, arguments: NoArguments) async throws -> EventSource<Message> {
        jet.eventStream()
    }
}

final class GraphitiTests: XCTestCase {
    private let resolver: TestResolver = .init()
    private var group = MultiThreadedEventLoopGroup(numberOfThreads: 4)

    deinit {
        try? group.syncShutdownGracefully()
    }

    func testAsyncSequenceSubscription() throws {
        let schema = try Schema<TestResolver, TestContext>.init {
            Type(Message.self) {
                Field("id", at: \.id)
                Field("content", at: \.content)
                Field("description", at: Message.description) {
                    Argument("formatting", at: \.formatting)
                }
            }

            Query {
                Field("hello", at: TestResolver.hello)
            }

            Mutation {
                Field("randomMessage", at: TestResolver.randomMessage) {
                    Argument("content", at: \.string)
                }
            }

            Subscription {
                SubscriptionField("onMessage", as: Message.self, atSub: TestResolver.onMessage)
            }
        }

        let start = Date()
        let query = """
        subscription {
            onMessage {
                id, content       
            }
        }
        """

        let subscriptionResult = try schema
            .subscribe(request: query, resolver: resolver, context: TestContext(), eventLoopGroup: group)
            .wait()

        guard let subscription = subscriptionResult.stream else {
            return XCTFail(subscriptionResult.errors.description)
        }

        guard let nozzle = subscription.nozzle() else {
            return XCTFail("Stream failed to be casted into proper types \(subscription))")
        }

        let expectation = XCTestExpectation(description: "Received a single message")
        Task.init {
            for await future in nozzle {
                let message = try await future.get()
                let expected = GraphQLResult(data: [
                    "onMessage": [
                        "id": "bob",
                        "content": "Bob"
                    ]
                ])
                if message == expected {
                    expectation.fulfill()
                }
                break
            }
            nozzle.shutdown()
        }

        Task.init {
            await resolver.engine.task(with: .next(.init(id: "bob", content: "Bob")))
            await resolver.engine.task(with: .next(.init(id: "bob2", content: "Bob2")))
        }

        wait(for: [expectation], timeout: 10)
        print(abs(start.timeIntervalSinceNow) * 1000)
    }
}