//
//  BuiltInTypesTests.swift
//  Pioneer
//
//  Created by d-exclaimation on 2:26 PM.
//  Copyright © 2021 d-exclaimation. All rights reserved.
//

import Foundation
import enum GraphQL.Map
import enum GraphQL.OperationType
@testable import Pioneer
import XCTest

final class BuiltInTypesTests: XCTestCase {
    /// Test ID Randomised features
    func testID() throws {
        let random = ID.random()
        XCTAssert(random.count == 10)
    }

    /// Test ID JSON Encoding
    func testIDJSON() throws {
        let myID: ID = "123"

        let data = try JSONEncoder().encode(myID)

        guard let result = String(data: data, encoding: .utf8) else {
            return XCTFail("Cannot create string from JSON Data")
        }

        XCTAssert(result == "\"123\"")
    }

    /// Test GraphQLRequest
    func testGraphQLGraphQLRequestuest() throws {
        // Correct operation type (query)
        let gql0 = GraphQLRequest(query: "query { field1 }")
        XCTAssertFalse(gql0.isIntrospection)
        guard let type0 = gql0.operationType else {
            return XCTFail("Cannot idenfity just query")
        }
        XCTAssert(type0 == OperationType.query, "Cannot idenfity just query")

        // Correct operation type (mutation)
        let gql1 = GraphQLRequest(query: "mutation { field1 }")
        XCTAssertFalse(gql1.isIntrospection)
        guard let type1 = gql1.operationType else {
            return XCTFail("Cannot idenfity just mutation")
        }
        XCTAssert(type1 == OperationType.mutation, "Cannot idenfity just mutation")

        // Correct operation type (subscription)
        let gql2 = GraphQLRequest(query: "subscription { field1 }")
        XCTAssertFalse(gql2.isIntrospection)
        guard let type2 = gql2.operationType else {
            return XCTFail("Cannot idenfity just subscription")
        }
        XCTAssert(type2 == OperationType.subscription, "Cannot idenfity just subscription")

        // Correct operation type with operation name
        let query = "subscription Op0 { field1 } mutation Op1 { field1 } query Op2 { field1 }"
        for (operationName, optype) in [("Op0", OperationType.subscription), ("Op1", OperationType.mutation), ("Op2", OperationType.query)] {
            let gql3 = GraphQLRequest(query: query, operationName: operationName)
            XCTAssertFalse(gql3.isIntrospection)
            guard let type3 = gql3.operationType else {
                return XCTFail("Cannot idenfity \(operationName)")
            }
            XCTAssert(type3 == optype, "Cannot idenfity just \(operationName)")
        }

        // Should decode correctly
        let decoded0 = """
        {
            "query": "query { field1 }"
        } 
        """.data(using: .utf8)?.to(GraphQLRequest.self)
        XCTAssertEqual(decoded0?.query, "query { field1 }")

        // Should decode correctly (with operation name)
        let decoded1 = """
        {
            "query": "query Name { field1 }",
            "operationName": "Name"
        } 
        """.data(using: .utf8)?.to(GraphQLRequest.self)
        XCTAssertEqual(decoded1?.query, "query Name { field1 }")
        XCTAssertEqual(decoded1?.operationName, "Name")

        // Should decode correctly (with operation name and variables)
        let decoded2 = """
        {
            "query": "query Name($count: 1) { field1(count: $count) }",
            "operationName": "Name",
            "variables": { "count": 1 }
        } 
        """.data(using: .utf8)?.to(GraphQLRequest.self)
        XCTAssertEqual(decoded2?.query, "query Name($count: 1) { field1(count: $count) }")
        XCTAssertEqual(decoded2?.operationName, "Name")
        XCTAssertEqual(decoded2?.variables?["count"], Map.number(1))

        // Should decode correctly (with null operation name and variables)
        let decoded3 = """
        {
            "query": "query { field1 }",
            "operationName": null,
            "variables": null
        } 
        """.data(using: .utf8)?.to(GraphQLRequest.self)
        XCTAssertEqual(decoded3?.query, "query { field1 }")

        // Should encode correctly
        let encoded = GraphQLRequest(query: "query { field }").jsonString
        XCTAssertNotEqual("{}", encoded)
        XCTAssertEqual("{\"query\":\"query { field }\"}", encoded)
    }
}
