//
//  Request+GraphQLRequest.swift
//  Pioneer
//
//  Created by d-exclaimation on 12:30.
//

import struct GraphQL.GraphQLError
import enum GraphQL.Map
import struct Vapor.Abort
import class Vapor.Request

extension Request: GraphQLRequestConvertible {
    public func body<T>(_ decodable: T.Type) throws -> T where T: Decodable {
        try content.decode(decodable)
    }

    public func searchParams<T>(_ decodable: T.Type, at: String) -> T? where T: Decodable {
        query[decodable, at: at]
    }

    public var isAcceptingGraphQLResponse: Bool {
        headers[.accept].contains(HTTPGraphQLRequest.mediaType)
    }
}
