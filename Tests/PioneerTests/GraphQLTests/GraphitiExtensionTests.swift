//
//  GraphitiExtensionTests.swift
//  Pioneer
//
//  Created by d-exclaimation on 2:48 PM.
//  Copyright © 2021 d-exclaimation. All rights reserved.
//

import Foundation
import Graphiti
import GraphQL
import NIO
@testable import Pioneer
import XCTest

final class GraphitiExtensionTests: XCTestCase {
    /// GraphQL Request Object
    /// 1. Should omit nil values
    func testDecodingGraphQLRequest() {
        let req = GraphQLRequest(query: "query { someField }", operationName: nil, variables: nil)
        XCTAssertEqual(req.jsonString, "{\"query\":\"query { someField }\"}")
    }

    /// GraphQL Request Object
    /// 1. Should have an accesible source property
    /// 2. Should be parsed properly into the correct GraphQL AST
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

    /// GraphQL Request Object
    /// 1. Should be able to identify Introspection query 100% of the time
    ///     - Introspection includes `__schema` and `__type` queries
    /// 2. Should not take account keyword given inside a string qoutes
    /// 3. Should not mistaken `__type` with `__typename`
    func testGraphQLRequestIntrospection() {
        let introspection = GraphQLRequest(query: "{ __schema { queryType { name } } }", operationName: nil, variables: nil)
        XCTAssert(introspection.isIntrospection)

        let introspection2 = GraphQLRequest(query: "{ __type(name: \"Droid\") { name } }", operationName: nil, variables: nil)
        XCTAssert(introspection2.isIntrospection)

        let query = GraphQLRequest(query: "{ someField(arg0: \"No __schema allowed\") { __typename } }", operationName: nil, variables: nil)
        XCTAssert(!query.isIntrospection)
    }
}
