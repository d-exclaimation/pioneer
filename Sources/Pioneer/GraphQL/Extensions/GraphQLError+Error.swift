//
//  GraphQLError+Error.swift
//  Pioneer
//
//  Created by d-exclaimation on 09:43.
//

import struct GraphQL.GraphQLError

extension Error {
    /// Get the GraphQLError version of this error
    public var graphql: GraphQLError {
        self as? GraphQLError ?? .init(self)
    }
}