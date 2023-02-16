//
//  Pioneer+Http.swift
//  Pioneer
//
//  Created by d-exclaimation on 11:34 AM.
//

import struct GraphQL.GraphQLError
import class GraphQL.GraphQLJSONEncoder
import enum GraphQL.Map
import enum GraphQL.OperationType
import Vapor

public extension Pioneer {
    /// Vapor-based HTTP Context builder
    typealias VaporHTTPContext = @Sendable (Request, Response) async throws -> Context

    /// Common Handler for GraphQL through HTTP
    /// - Parameter req: The HTTP request being made
    /// - Returns: A response from the GraphQL operation execution properly formatted
    func httpHandler(req: Request, context: @escaping VaporHTTPContext) async throws -> Response {
        try await httpHandler(req: req, using: GraphQLJSONEncoder(), context: context)
    }

    /// Common Handler for GraphQL through HTTP
    /// - Parameters:
    ///   - req: The HTTP request being made
    ///   - using: The custom content encoder
    /// - Returns: A response from the GraphQL operation execution properly formatted
    func httpHandler(req: Request, using encoder: ContentEncoder, context: @escaping VaporHTTPContext) async throws -> Response {
        let res = Response()
        do {
            // Parsing GraphQLRequest and Context
            let httpReq = try req.httpGraphQL
            let context = try await context(req, res)

            // Executing into GraphQLResult
            let httpRes = await executeHTTPGraphQLRequest(for: httpReq, with: context, using: req.eventLoop)
            try res.content.encode(httpRes.result, using: encoder)
            res.status = httpRes.status
            httpRes.headers?.forEach {
                res.headers.replaceOrAdd(name: $0, value: $1)
            }
            return res
        } catch let v as GraphQLViolation {
            return try GraphQLError(message: v.message)
                .response(with: v.status(req.isAcceptingGraphQLResponse))
        } catch let error as AbortError {
            return try error.response(using: res)
        } catch {
            return try error.graphql.response(with: .internalServerError)
        }
    }
}
