//
//  PioneerStatelessTests.swift
//  Pioneer
//
//  Created by d-exclaimation on 9:44 PM.
//  Copyright © 2021 d-exclaimation. All rights reserved.
//

import Graphiti
import struct GraphQL.GraphQLResult
import enum GraphQL.Map
import NIO
@testable import Pioneer
import XCTest

func AlwaysZero<ObjectType, Arguments>() -> GraphQLMiddleware<ObjectType, Void, Arguments, Int> {
    return { _, _ in 0 }
}

final class PioneerStatelessTests: XCTestCase {
    /// Simple message type with a custom computed properties
    struct Message: Codable, Identifiable {
        var id: String = UUID().uuidString
        var content: String

        struct Arg: Codable {
            var formatting: String
        }
    }

    struct Resolver {
        func sync(context _: (), arguments _: NoArguments) -> Int { 0 }

        struct Arg0: Codable {
            var allowed: Bool
        }

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

    private var group = MultiThreadedEventLoopGroup(numberOfThreads: 4)
    private let resolver = Resolver()
    private let schema = try! Schema<Resolver, Void> {
        Type(Message.self) {
            Field("id", at: \.id)
            Field("id", at: \.content)
        }

        Query {
            Field("sync", at: Resolver.sync)
            Field("syncWithMiddleware", at: Resolver.sync, use: [AlwaysZero()])
            Field("syncWithArg", at: Resolver.syncWithArg) {
                Argument("allowed", at: \.allowed)
            }

            Field("async", at: Resolver.async)
            Field("asyncWithMiddleware", at: Resolver.async, use: [AlwaysZero()])
            Field("asyncMessage", at: Resolver.asyncMessage)
        }
    }

    private lazy var pioneer = Pioneer(schema: schema, resolver: resolver)

    override func tearDownWithError() throws {
        try group.syncShutdownGracefully()
    }

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
        ].map {
            GraphQLRequest(query: $0, operationName: nil, variables: nil)
        }

        let expectation = [
            Map.dictionary(["sync": Map.number(0)]),
            Map.dictionary(["syncWithArg": .number(1)]),
            Map.dictionary(["async": .number(2)]),
        ].map {
            GraphQLResult(data: $0)
        }

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
        // Sync
        let gql0 = GraphQLRequest(
            query: "query { syncWithMiddleware }",
            operationName: nil,
            variables: nil
        )
        let exp0 = GraphQLResult(data: [
            "syncWithMiddleware": .int(0),
        ])
        let res0 = await pioneer.executeOperation(for: gql0, with: (), using: group)
        XCTAssertEqual(res0, exp0)

        // Async
        let gql1 = GraphQLRequest(
            query: "query { asyncWithMiddleware }",
            operationName: nil,
            variables: nil
        )
        let exp1 = GraphQLResult(data: [
            "asyncWithMiddleware": .int(0),
        ])
        let res1 = await pioneer.executeOperation(for: gql1, with: (), using: group)
        XCTAssertEqual(res1, exp1)
    }
}
