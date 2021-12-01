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
            let res = try await pioneer
                .schema
                .execute(request: curr.query, resolver: pioneer.resolver, context: (), eventLoopGroup: group)
                .get()

            XCTAssertEqual(res, expect)
        }
    }

    func testGraphQLRequest() {
        let introspection = GraphQLRequest(query: "{ __schema { queryType { name } } }", operationName: nil, variables: nil)
        XCTAssert(introspection.isIntrospection)

        let introspection2 = GraphQLRequest(query: "{ __type(name: \"Droid\") { name } }", operationName: nil, variables: nil)
        XCTAssert(introspection2.isIntrospection)

        let query = GraphQLRequest(query: "{ someField(arg0: \"No __schema allowed\") { __typename } }", operationName: nil, variables: nil)
        XCTAssert(!query.isIntrospection)
    }
}
