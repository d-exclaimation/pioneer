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
    }
}
