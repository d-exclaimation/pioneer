//
//  GraphQLRequest.swift
//  GraphQLAsyncSequence
//
//  Created by d-exclaimation on 12:49 AM.
//  Copyright © 2021 d-exclaimation. All rights reserved.
//

import Foundation
import GraphQL

public struct GraphQLRequest: Codable {
    public var query: String
    public var operationName: String?
    public var variables: [String: Map]?

    public var source: Source {
        .init(body: query)
    }

    public func operationType() throws -> OperationType? {
        let ast = try parse(source: source)
        return ast.definitions
            .compactMap { def -> OperationType? in
                (def as? OperationDefinition)?.operation
            }
            .first
    }

    public var isIntrospection: Bool {
        query.contains("__schema") || query.contains("__type")
    }
}
