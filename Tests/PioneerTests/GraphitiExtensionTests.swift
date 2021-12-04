//
//  GraphitiExtensionTests.swift
//  Pioneer
//
//  Created by d-exclaimation on 2:48 PM.
//  Copyright © 2021 d-exclaimation. All rights reserved.
//

import Foundation
import XCTest
import GraphQL
import Graphiti
import NIO
import Desolate
@testable import Pioneer

final class GraphitiExtensionTests: XCTestCase {
    func testDecodingGraphQLRequest() {
        let req = GraphQLRequest(query: "query { someField }", operationName: nil, variables: nil)
        XCTAssertEqual(req.jsonString, "{\"query\":\"query { someField }\"}")
    }

    func testGraphQLRequestSource() throws {
        let req = GraphQLRequest(query: "query { someField }", operationName: nil, variables: nil)
        let ast = try parse(source: req.source)
        guard !ast.definitions.isEmpty else {
            return XCTFail("Definition is empty")
        }
        guard let def = ast.definitions[0] as? OperationDefinition else {
            return XCTFail("Definition isn't valid")
        }
        XCTAssert(def.operation == OperationType.query)
        XCTAssert(!def.selectionSet.selections.isEmpty)
        guard let field = def.selectionSet.selections[0] as? GraphQL.Field else {
            return XCTFail("Definition isn't valid")
        }
        XCTAssert(field.name.value == "someField")
    }

    func testGraphQLRequestIntrospection() {
        let introspection = GraphQLRequest(query: "{ __schema { queryType { name } } }", operationName: nil, variables: nil)
        XCTAssert(introspection.isIntrospection)

        let introspection2 = GraphQLRequest(query: "{ __type(name: \"Droid\") { name } }", operationName: nil, variables: nil)
        XCTAssert(introspection2.isIntrospection)

        let query = GraphQLRequest(query: "{ someField(arg0: \"No __schema allowed\") { __typename } }", operationName: nil, variables: nil)
        XCTAssert(!query.isIntrospection)
    }
}
