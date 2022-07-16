//
//  BuiltInTypesTests.swift
//  Pioneer
//
//  Created by d-exclaimation on 2:26 PM.
//  Copyright © 2021 d-exclaimation. All rights reserved.
//

import Foundation
import XCTest
import GraphQL
@testable import Pioneer

final class BuiltInTypesTests: XCTestCase {
    typealias Req = Pioneer<Void, Void>.GraphQLRequest
    
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
    func testGraphQLReques() throws {
        let gql0 = Req(query: "query { field1 }")
        XCTAssertFalse(gql0.isIntrospection)
        guard let type0 = try? gql0.operationType() else {
            return XCTFail("Cannot idenfity just query")
        }
        XCTAssert(type0 == OperationType.query, "Cannot idenfity just query")
        
        let gql1 = Req(query: "mutation { field1 }")
        XCTAssertFalse(gql1.isIntrospection)
        guard let type1 = try? gql1.operationType() else {
            return XCTFail("Cannot idenfity just mutation")
        }
        XCTAssert(type1 == OperationType.mutation, "Cannot idenfity just mutation")
        
        let gql2 = Req(query: "subscription { field1 }")
        XCTAssertFalse(gql2.isIntrospection)
        guard let type2 = try? gql2.operationType() else {
            return XCTFail("Cannot idenfity just subscription")
        }
        XCTAssert(type2 == OperationType.subscription, "Cannot idenfity just subscription")
        
        let query = "subscription Op0 { field1 } mutation Op1 { field1 } query Op2 { field1 }"
        for (operationName, optype) in [("Op0", OperationType.subscription), ("Op1", OperationType.mutation), ("Op2", OperationType.query)] {
            let gql3 = Req(query: query, operationName: operationName)
            XCTAssertFalse(gql3.isIntrospection)
            guard let type3 = try? gql3.operationType() else {
                return XCTFail("Cannot idenfity \(operationName)")
            }
            XCTAssert(type3 == optype, "Cannot idenfity just \(operationName)")
        }

        let decoded0 = """
        {
            "query": "query { field1 }"
        } 
        """.data(using: .utf8)?.to(Req.self)
        XCTAssertEqual(decoded0?.query, "query { field1 }")


        let decoded1 = """
        {
            "query": "query Name { field1 }",
            "operationName": "Name"
        } 
        """.data(using: .utf8)?.to(Req.self)
        XCTAssertEqual(decoded1?.query, "query Name { field1 }")
        XCTAssertEqual(decoded1?.operationName, "Name")

        let decoded2 = """
        {
            "query": "query Name($count: 1) { field1(count: $count) }",
            "operationName": "Name",
            "variables": { "count": 1 }
        } 
        """.data(using: .utf8)?.to(Req.self)
        XCTAssertEqual(decoded2?.query, "query Name($count: 1) { field1(count: $count) }")
        XCTAssertEqual(decoded2?.operationName, "Name")
        XCTAssertEqual(decoded2?.variables?["count"], Map.number(1))

        let decoded3 = """
        {
            "query": "query { field1 }",
            "operationName": null,
            "variables": null
        } 
        """.data(using: .utf8)?.to(Req.self)
        XCTAssertEqual(decoded3?.query, "query { field1 }")


        let encoded = Req(query: "query { field }").jsonString
        XCTAssertNotEqual("{}", encoded)
        XCTAssertEqual("{\"query\":\"query { field }\"}", encoded)
    }
}
