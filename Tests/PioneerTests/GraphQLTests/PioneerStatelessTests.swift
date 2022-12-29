//
//  PioneerStatelessTests.swift
//  Pioneer
//
//  Created by d-exclaimation on 9:44 PM.
//  Copyright © 2021 d-exclaimation. All rights reserved.
//

import Foundation
import Graphiti
import GraphQL
import NIO
@testable import Pioneer
import XCTest

struct TestResolver1 {
    func sync(context _: (), arguments _: NoArguments) -> Int { 0 }

    struct Arg0: Codable { var allowed: Bool }

    func syncWithArg(context _: (), arguments: Arg0) -> Int { arguments.allowed ? 1 : 0 }

    func async(context _: (), arguments _: NoArguments) async throws -> Int {
        try await Task.sleep(nanoseconds: 1000 * 1000 * 300)
        return 2
    }

    func asyncMessage(context _: (), arguments _: NoArguments) async throws -> Message {
        try await Task.sleep(nanoseconds: 1000 * 1000 * 300)
        return Message(content: "Hello")
    }
}

func AlwaysFail<ObjectType, Arguments>() -> GraphQLMiddleware<ObjectType, Void, Arguments, Int> {
    return { info, _ in
        return 0
    }
}

final class PioneerStatelessTests: XCTestCase {
    private var group = MultiThreadedEventLoopGroup(numberOfThreads: 4)
    private let resolver = TestResolver1()
    private let schema = try! Schema<TestResolver1, Void> {
        Graphiti.Type(Message.self) {
            Graphiti.Field("id", at: \.id)
            Graphiti.Field("id", at: \.content)
        }

        Graphiti.Query {
            Graphiti.Field("sync", at: TestResolver1.sync)
            Graphiti.Field("syncWithMiddleware", at: TestResolver1.sync, use: [AlwaysFail()])
            Graphiti.Field("syncWithArg", at: TestResolver1.syncWithArg) {
                Graphiti.Argument("allowed", at: \.allowed)
            }

            Graphiti.Field("async", at: TestResolver1.async)
            Graphiti.Field("asyncWithMiddleware", at: TestResolver1.async, use: [AlwaysFail()])
            Graphiti.Field("asyncMessage", at: TestResolver1.asyncMessage)
        }
    }

    private lazy var pioneer = Pioneer(schema: schema, resolver: resolver)

    /// Pioneer
    /// 1. Should be able to block certain operations
    /// 2. Should allow only operations defined in the `allowing` array
    func testOperationBlocking() throws {
        let gql = GraphQLRequest(
            query: "query { sync }",
            operationName: nil,
            variables: nil
        )
        let res0 = pioneer.allowed(from: gql, allowing: [.mutation])
        XCTAssert(!res0)
        let res1 = pioneer.allowed(from: gql, allowing: [.query, .mutation])
        XCTAssert(res1)
    }

    /// Pioneer
    /// 1. Shpuld have all the required variables to execute an operation
    /// 2. Should be able to execute and resolve operations
    func testHandler() async throws {
        let gql = [
            "query { sync }",
            "query { syncWithArg(allowed: true) }",
            "query { async }",
        ].map { GraphQLRequest(query: $0, operationName: nil, variables: nil) }

        let expectation = [
            Map.dictionary(["sync": Map.number(0)]),
            ["syncWithArg": .number(1)],
            ["async": .number(2)],
        ].map { GraphQLResult(data: $0) }

        for i in gql.indices {
            let curr = gql[i]
            let expect = expectation[i]
            let res = await pioneer.executeOperation(for: curr, with: (), using: group)
            XCTAssertEqual(res, expect)
        }
    }

    /// Pioneer's GraphQLMiddleware 
    /// 1. Should intercept before the resolver
    func testMiddleware() async throws { 
        let gql0 = GraphQLRequest(
            query: "query { syncWithMiddleware }",
            operationName: nil,
            variables: nil
        ) 
        let exp0 = GraphQLResult(data: [
            "syncWithMiddleware": .int(0)
        ])

        let res0 = await pioneer.executeOperation(for: gql0, with: (), using: group)
        XCTAssertEqual(res0, exp0)

       let gql1 = GraphQLRequest(
            query: "query { asyncWithMiddleware }",
            operationName: nil,
            variables: nil
        ) 
        let exp1 = GraphQLResult(data: [
            "asyncWithMiddleware": .int(0)
        ])

        let res1 = await pioneer.executeOperation(for: gql1, with: (), using: group)
        XCTAssertEqual(res1, exp1)
    }
}
