//
//  Pioneer+Http.swift
//  Pioneer
//
//  Created by d-exclaimation on 11:34 AM.
//

import Vapor
import enum GraphQL.OperationType
import enum GraphQL.Map
import struct GraphQL.GraphQLError
import class GraphQL.GraphQLJSONEncoder


extension Pioneer {
    /// Vapor-based HTTP Context builder
    public typealias VaporHTTPContext = @Sendable (Request, Response) async throws -> Context

    /// Common Handler for GraphQL through HTTP
    /// - Parameter req: The HTTP request being made
    /// - Returns: A response from the GraphQL operation execution properly formatted
    public func httpHandler(req: Request, context: @escaping VaporHTTPContext) async throws -> Response {
        try await httpHandler(req: req, using: GraphQLJSONEncoder(), context: context)
    }
    
    /// Common Handler for GraphQL through HTTP
    /// - Parameters:
    ///   - req: The HTTP request being made
    ///   - using: The custom content encoder
    /// - Returns: A response from the GraphQL operation execution properly formatted
    public func httpHandler(req: Request, using encoder: ContentEncoder, context: @escaping VaporHTTPContext) async throws -> Response {
        // Check for CSRF Prevention
        guard !csrfVulnerable(given: req.headers) else {
            return try GraphQLError(
                message: "Operation has been blocked as a potential Cross-Site Request Forgery (CSRF)."
            )
            .response(with: .badRequest)
        }
        do {
            let gql = try req.graphql
            return try await handle(req: req, from: gql, allowing: httpStrategy.allowed(for: req.method), using: encoder, context: context)
        } catch let error as AbortError {
            return try GraphQLError(message: error.reason).response(with: error.status)
        } catch {
            return try error.graphql.response(with: .internalServerError)
        }
    }

    /// Handle execution for GraphQL operation
    /// - Parameters:
    ///   - req: The HTTP Request
    ///   - gql: The GraphQL request for the operation
    ///   - allowing: The allowed operation type
    /// - Returns: A response with proper http status code and a well formatted body
    internal func handle(req: Request, from gql: GraphQLRequest, allowing: [OperationType], using encoder: ContentEncoder, context: @escaping VaporHTTPContext) async throws -> Response {
        guard allowed(from: gql, allowing: allowing) else {
            return try GraphQLError(message: "Operation of this type is not allowed and has been blocked")
                .response(with: .badRequest)
        }
        let errors = validationRules(using: schema, for: gql)
        guard errors.isEmpty else {
            return try errors.response(with: .badRequest)
        }

        let res = Response()
        do {
            let context = try await context(req, res)
            let result = await executeOperation(for: gql, with: context, using: req.eventLoop)
            try res.content.encode(result, using: encoder)
            return res
        } catch let error as AbortError {
            return try error.response(using: res)
        } catch {
            return try error.graphql.response(using: res)
        }
    }
}
