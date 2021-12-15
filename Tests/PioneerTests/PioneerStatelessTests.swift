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
    func sync(context: (), arguments: NoArguments) -> Int { 0 }

    struct Arg0: Codable { var allowed: Bool }

    func syncWithArg(context: (), arguments: Arg0) -> Int { arguments.allowed ? 1 : 0 }

    func async(context: (), arguments: NoArguments) async throws -> Int {
        try await Task.sleep(nanoseconds: 1000 * 1000 * 300)
        return 2
    }

    func asyncMessage(context: (), arguments: NoArguments) async throws -> Message {
        try await Task.sleep(nanoseconds: 1000 * 1000 * 300)
        return Message(content: "Hello")
    }
}

final class PioneerStatelessTests: XCTestCase {
    private var group = MultiThreadedEventLoopGroup(numberOfThreads: 4)
    private let resolver = TestResolver1()
    private let schema = try! Schema<TestResolver1, Void>.init {
        Graphiti.Type(Message.self) {
            Graphiti.Field("id", at: \.id)
            Graphiti.Field("id", at: \.content)
        }

        Graphiti.Query {
            Graphiti.Field("sync", at: TestResolver1.sync)
            Graphiti.Field("syncWithArg", at: TestResolver1.syncWithArg) {
                Graphiti.Argument("allowed", at: \.allowed)
            }

            Graphiti.Field("async", at: TestResolver1.async)
            Graphiti.Field("asyncMessage", at: TestResolver1.asyncMessage)
        }
    }

    private lazy var pioneer = Pioneer.init(schema: schema, resolver: resolver)

    /// Pioneer
    /// 1. Should be able to block certain operations
    /// 2. Should allow only operations defined in the `allowing` array
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

    /// Pioneer
    /// 1. Shpuld have all the required variables to execute an operation
    /// 2. Should be able to execute and resolve operations
    func testHandler() async throws {
        let gql = [
            "query { sync }",
            "query { syncWithArg(allowed: true) }",
            "query { async }"
        ].map { GraphQLRequest(query: $0, operationName: nil, variables: nil) }

        let expectation = [
            Map.dictionary(["sync": Map.number(0)]),
            ["syncWithArg": .number(1)],
            ["async": .number(2)]
        ].map { GraphQLResult.init(data: $0) }

        for i in gql.indices {
            let curr = gql[i]
            let expect = expectation[i]
            let res = try await executeGraphQL(schema: pioneer.schema, request: curr.query, resolver: pioneer.resolver, context: (), eventLoopGroup: group)

            XCTAssertEqual(res, expect)
        }
    }

}
