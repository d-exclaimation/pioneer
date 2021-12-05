//
//  GraphQLRequest.swift
//  GraphQLAsyncSequence
//
//  Created by d-exclaimation on 12:49 AM.
//  Copyright © 2021 d-exclaimation. All rights reserved.
//

import Foundation
import GraphQL

/// GraphQL Request according to the spec
public struct GraphQLRequest: Codable {
    /// Query string
    public var query: String
    /// Name of the operation being ran if there are more than one included in this query.
    public var operationName: String?
    /// Variables seperated and assign to constant in the query
    public var variables: [String: Map]?

    /// Getter a GraphQL AST Source from query
    public var source: Source {
        .init(body: query)
    }

    /// Getting parsed operationType
    public func operationType() throws -> OperationType? {
        let ast = try parse(source: source)
        return ast.definitions
            .compactMap { def -> OperationType? in
                (def as? OperationDefinition)?.operation
            }
            .first
    }

    /// Check if query is any type of introspection
    public var isIntrospection: Bool {
        guard let ast = try? parse(source: source) else { return false }
        return ast.definitions.contains { def in
            guard let operation = def as? OperationDefinition else { return false }
            return operation.selectionSet.selections.contains { select in
                guard let field = select as? Field else { return false }
                return field.name.value == "__schema" || field.name.value == "__type"
            }
        }
    }
}