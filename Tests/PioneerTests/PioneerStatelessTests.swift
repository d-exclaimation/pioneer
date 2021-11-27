//
//  PioneerStatelessTests.swift
//  Pioneer
//
//  Created by d-exclaimation on 9:44 PM.
//  Copyright © 2021 d-exclaimation. All rights reserved.
//

import Foundation
import XCTest
import GraphQL
import Graphiti
import NIO
import Desolate
@testable import Pioneer

struct TestResolver1 {
    func sync(context: (), arguments: NoArguments) -> Int {
        0
    }

    struct Arg0: Codable {
        var allowed: Bool
    }

    func syncWithArg(context: (), arguments: Arg0) -> Int {
        arguments.allowed ? 1 : 0
    }

    func async(context: (), arguments: NoArguments) async throws -> Int {
        await Task.sleep(1000 * 1000 * 300)
        return 2
    }

    func asyncMessage(context: (), arguments: NoArguments) async throws -> Message {
        await Task.sleep(1000 * 1000 * 300)
        return Message(content: "Hello")
    }
}

class PioneerStatelessTests: XCTestCase {
    private var group = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
    private let resolver = TestResolver1()
    private let schema = try! Schema<TestResolver1, ()>.init {
        Type(Message.self) {
            Field("id", at: \.id)
            Field("id", at: \.content)
        }

        Query {
            Field("sync", at: TestResolver1.sync)
            Field("syncWithArg", at: TestResolver1.syncWithArg) {
                Argument("allowed", at: \.allowed)
            }

            Field("async", at: TestResolver1.async)
            Field("asyncMessage", at: TestResolver1.asyncMessage)
        }
    }

    private lazy var pioneer = Pioneer(schema: schema, resolver: resolver, contextBuilder: { _ in ()})

    func testOperationBlocking() throws {
        let gql = GraphQLRequest(
            query: "query { sync }",
            operationName: nil,
            variables: nil
        )
        let res0 = try pioneer.allowed(from: gql, allowing: [.mutation])
        XCTAssert(!res0)
        let res1 = try pioneer.allowed(from: gql, allowing: [.query, .mutation])
        XCTAssert(res1)
    }

    func testHandler() async throws {
        let gql = [
            GraphQLRequest(query: "query { sync }", operationName: nil, variables: nil),
            GraphQLRequest(query: "query { syncWithArg(allowed: true) }", operationName: nil, variables: nil),
            GraphQLRequest(query: "query { async }", operationName: nil, variables: nil),
        ]
        let expectation = [
            GraphQLResult(data: [
                "sync": .number(0)
            ]),
            GraphQLResult(data: [
                "syncWithArg": .number(1)
            ]),
            GraphQLResult(data: [
                "async": .number(2)
            ]),
        ]
        for i in gql.indices {
            let curr = gql[i]
            let expect = expectation[i]
            let res = try await pioneer
                .schema
                .execute(request: curr.query, resolver: pioneer.resolver, context: (), eventLoopGroup: group)
                .get()

            XCTAssertEqual(res, expect)
        }
    }
}
