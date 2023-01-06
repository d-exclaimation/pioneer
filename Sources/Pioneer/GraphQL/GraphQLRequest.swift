//
//  GraphQLRequest.swift
//  GraphQLAsyncSequence
//
//  Created by d-exclaimation on 12:49 AM.
//

import Foundation
import GraphQL

/// GraphQL Request according to the spec
public struct GraphQLRequest: Codable, @unchecked Sendable {
    private enum Key: String, CodingKey, CaseIterable {
        case query, operationName, variables, extensions
    }

    /// Query string
    public var query: String
    /// Name of the operation being ran if there are more than one included in this query.
    public var operationName: String?
    /// Variables seperated and assign to constant in the query
    public var variables: [String: Map]?
    /// Extensions for the request
    public var extensions: [String: Map]?

    /// Parsed GraphQL Document from request
    public var ast: Document?

    /// Getter a GraphQL AST Source from query
    public var source: Source {
        .init(body: query)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Key.self)
        guard container.contains(.query) else {
            throw ParsingIssue.missingQuery
        }
        do {
            let query = try container.decode(String.self, forKey: .query)
            let operationName = try container.decodeIfPresent(String?.self, forKey: .operationName)
            let variables = try container.decodeIfPresent([String: Map]?.self, forKey: .variables)
            let extensions = try container.decodeIfPresent([String: Map]?.self, forKey: .extensions)
            self.init(
                query: query,
                operationName: operationName ?? nil,
                variables: variables ?? nil,
                extensions: extensions ?? nil
            )
        } catch {
            throw ParsingIssue.invalidForm
        }
    }

    public init(
        query: String,
        operationName: String? = nil,
        variables: [String: Map]? = nil,
        extensions _: [String: Map]? = nil
    ) {
        self.query = query
        self.operationName = operationName
        self.variables = variables
        ast = try? parse(source: .init(body: query))
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Key.self)
        try container.encode(query, forKey: .query)
        try container.encodeIfPresent(operationName, forKey: .operationName)
        try container.encodeIfPresent(variables, forKey: .variables)
        try container.encodeIfPresent(extensions, forKey: .extensions)
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

    /// Known possible failure in parsing GraphQLRequest
    public enum ParsingIssue: Error, @unchecked Sendable {
        case missingQuery
        case invalidForm
    }

    /// GraphQL over HTTP spec accept-type
    static var mediaType = "application/graphql-response+json"
}
