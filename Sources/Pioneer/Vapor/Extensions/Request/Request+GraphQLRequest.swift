//
//  Request+GraphQLRequest.swift
//  Pioneer
//
//  Created by d-exclaimation on 12:30.
//

import class Vapor.Request
import struct Vapor.Abort
import struct GraphQL.GraphQLError
import enum GraphQL.Map

extension Request {
    /// Get the GraphQLRequest from the request
    public var graphql: GraphQLRequest {
        get throws {
            switch (self.method) {
            case .GET:
                // Query is most important and should always be there, otherwise reject request
                guard let query: String = self.query[String.self, at: "query"] else {
                    throw Abort(.badRequest,
                        reason: "Unable to parse query and identify operation. Specify the 'query' query string parameter with the GraphQL query."
                    )
                }
                let variables: [String: Map]? = self.query[String.self, at: "variables"]
                    .flatMap { $0.data(using: .utf8)?.to([String: Map].self) }
                let operationName: String? = self.query[String.self, at: "operationName"]
                return GraphQLRequest(query: query, operationName: operationName, variables: variables)

            case .POST:
                do {
                    return try self.content.decode(GraphQLRequest.self)
                } catch {
                    throw Abort(.badRequest,
                        reason: "Unable to parse query and identify operation"
                    )
                }

            default:
                throw Abort(.badRequest, reason: "Invalid operation method for GraphQL request")
            }
        }
    }
}