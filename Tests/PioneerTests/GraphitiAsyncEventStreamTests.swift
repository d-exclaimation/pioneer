//
//  GraphitiAsyncEventStreamTests.swift
//  Pioneer
//
//  Created by d-exclaimation on 7:17 PM.
//  Copyright © 2021 d-exclaimation. All rights reserved.
//

import Foundation
import XCTest
import GraphQL
import Graphiti
import NIO
import Desolate
@testable import Pioneer


struct Message: Codable, Identifiable {
    var id: String = UUID().uuidString
    var content: String
}

struct TestContext {}

struct TestResolver {
    let (jet, engine) = Jet<Message>.desolate()

    func hello(context: TestContext, arguments: NoArguments) -> String {
        "Hello GraphQL!!"
    }

    struct StringArguments: Codable {
        var string: String
    }

    func randomMessage(context: TestContext, arguments: StringArguments, group: EventLoopGroup) -> EventLoopFuture<Message> {
        group.task { () async -> Message in
            let message = Message(content: arguments.string)
            engine.tell(with: .next(message))
            return message
        }
    }

    func onMessage(context: TestContext, arguments: NoArguments) -> GraphQL.EventStream<Message> {
        jet.eventStream()
    }
}

struct TestAPI: API {
    let resolver: TestResolver = TestResolver()
    let context: TestContext

    let schema = try! Schema<TestResolver, TestContext>.init {
        Type(Message.self) {
            Field("id", at: \.id)
            Field("content", at: \.content)
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
}

extension EventLoopGroup {
    typealias SendFunction<Value> = () async -> Value
    func task<Value>(_ body: @escaping SendFunction<Value>) -> EventLoopFuture<Value> {
        let promise = next().makePromise(of: Value.self)
        Task.init {
            let value = await body()
            promise.succeed(value)
        }
        return promise.futureResult
    }
}

class GraphitiTests: XCTestCase {
    private let api: TestAPI = .init(context: .init())
    private var group = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)

    deinit {
        try? group.syncShutdownGracefully()
    }

    func testAsyncSequenceSubscription() throws {
        let start = Date()
        let query = """
        subscription {
            onMessage {
                id, content
            }
        }
        """

        let subscriptionResult = try api
            .subscribe(request: query, context: TestContext(), on: group)
            .wait()

        guard let subscription = subscriptionResult.stream else {
            return XCTFail(subscriptionResult.errors.description)
        }

        guard let stream = subscription as? AsyncGraphQLNozzle else {
            return XCTFail("Stream failed to be casted into proper types \(subscription))")
        }

        let expectation = XCTestExpectation(description: "Received a single message")
        Task.init {
            let asyncStream = stream.sequence
            for await future in asyncStream {
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
            asyncStream.shutdown()
        }

        Task.init {
            await api.resolver.engine.task(with: .next(.init(id: "bob", content: "Bob")))
            await api.resolver.engine.task(with: .next(.init(id: "bob2", content: "Bob2")))
        }

        wait(for: [expectation], timeout: 10)
        print(abs(start.timeIntervalSinceNow) * 1000)
    }
}