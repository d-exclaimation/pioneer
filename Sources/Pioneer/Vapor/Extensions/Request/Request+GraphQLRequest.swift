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

public extension Request {
    /// Get the GraphQLRequest from the request
    var graphql: GraphQLRequest {
        get throws {
            switch self.method {
            case .GET:
                // Query is most important and should always be there, otherwise reject request
                guard let query: String = self.query[String.self, at: "query"] else {
                    throw Abort(.badRequest,
                                reason: "Unable to parse query and identify operation. Specify the 'query' query string parameter with the GraphQL query.")
                }
                let variables: [String: Map]? = self.query[String.self, at: "variables"]
                    .flatMap { $0.data(using: .utf8)?.to([String: Map].self) }
                let operationName: String? = self.query[String.self, at: "operationName"]
                return GraphQLRequest(query: query, operationName: operationName, variables: variables)

            case .POST:
                guard !headers[.contentType].isEmpty else {
                    throw Abort(.badRequest, reason: "Invalid content-type")
                }
                do {
                    return try self.content.decode(GraphQLRequest.self)
                } catch GraphQLRequest.ParsingIssue.missingQuery {
                    throw Abort(isAcceptingGraphQLResponse ? .badRequest : .ok,
                                reason: "Missing query parameter")
                } catch GraphQLRequest.ParsingIssue.invalidForm {
                    throw Abort(isAcceptingGraphQLResponse ? .badRequest : .ok,
                                reason: "Invalid GraphQL request form")
                } catch {
                    throw Abort(.badRequest, reason: "Unable to parse JSON")
                }

            default:
                throw Abort(.badRequest, reason: "Invalid operation method for GraphQL request")
            }
        }
    }

    /// Is request accepting GraphQL media type
    var isAcceptingGraphQLResponse: Bool {
        headers[.accept].contains(GraphQLRequest.mediaType)
    }
}
