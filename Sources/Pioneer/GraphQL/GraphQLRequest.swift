//
//  GraphQLRequest.swift
//  GraphQLAsyncSequence
//
//  Created by d-exclaimation on 12:49 AM.
//

import Foundation
import GraphQL

/// GraphQL Request according to the spec
public struct GraphQLRequest: Codable {
    private enum Key: String, CodingKey {
        case query, operationName, variables
    }

    /// Query string
    public var query: String
    /// Name of the operation being ran if there are more than one included in this query.
    public var operationName: String?
    /// Variables seperated and assign to constant in the query
    public var variables: [String: Map]?

    /// Parsed GraphQL Document from request
    public var ast: Document?

    /// Getter a GraphQL AST Source from query
    public var source: Source {
        .init(body: query)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Key.self)
        let query = try container.decode(String.self, forKey: .query)
        let operationName = try? container.decodeIfPresent(String.self, forKey: .operationName)
        let variables = try? container.decodeIfPresent([String: Map].self, forKey: .variables)
        self.init(query: query, operationName: operationName, variables: variables)
    }
    

    public init(query: String, operationName: String? = nil, variables: [String: Map]? = nil) {
        self.query = query
        self.operationName = operationName
        self.variables = variables
        self.ast = try? parse(source: .init(body: query))
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Key.self)
        try container.encode(query, forKey: .query)
        try container.encodeIfPresent(operationName, forKey: .operationName)
        try container.encodeIfPresent(variables, forKey: .variables)
    }   

    /// Getting parsed operationType
    public var operationType: OperationType? {
        guard let ast = ast else { return nil }
        let operations = ast.definitions
            .compactMap { def -> OperationDefinition? in
                def as? OperationDefinition
            }
            
        guard let operationName = operationName else {
            return operations.first?.operation
        }
        
        return operations
            .first {
                guard let name = $0.name?.value else { return false }
                return operationName == name
            }?
            .operation
    }

    /// Check if query is any type of introspection
    public var isIntrospection: Bool {
        guard let ast = ast else { return false }
        return ast.definitions.contains { def in
            guard let operation = def as? OperationDefinition else { return false }
            return operation.selectionSet.selections.contains { select in
                guard let field = select as? Field else { return false }
                return field.name.value == "__schema" || field.name.value == "__type"
            }
        }
    }
}
