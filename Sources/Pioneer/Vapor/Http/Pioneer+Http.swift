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
        guard isCSRFProtected(isActive: httpStrategy == .csrfPrevention, on: req) else {
            return try GraphQLError(
                message: "Operation has been blocked as a potential Cross-Site Request Forgery (CSRF)." +
                "Either specify a 'content-type' header that is not 'text/plain', 'application/x-www-form-urlencoded', or 'multipart/form-data' " +
                " or provide a non-empty value for one of the following headers: 'x-apollo-operation-name' or 'apollo-require-preflight'")
            .response(with: .badRequest)
        }
        do {
            let gql = try req.graphql
            return try await handle(req: req, from: gql, allowing: httpStrategy.allowed(for: req.method), using: encoder, context: context)
        } catch let error as Abort {
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
    
    
    /// Check if request is CSRF protected if prevention is active
    /// - Parameters:
    ///   - isActive: True if enable prevention and checking
    ///   - req: The request being made
    /// - Returns: True if the request is CSRF protected
    internal func isCSRFProtected(isActive: Bool = true, on req: Request) -> Bool {
        guard isActive else {
            return true
        }
        let hasPreflight = !req.headers[HTTPHeaders.Name("Apollo-Require-Preflight")].isEmpty
        let hasOperationName = !req.headers[HTTPHeaders.Name("X-Apollo-Operation-Name")].isEmpty
        if hasPreflight || hasOperationName {
            return true
        }
        let restrictedHeaders = ["text/plain", "application/x-www-form-urlencoded", "multipart/form-data"]
        let contentTypes = req.headers[.contentType]
        return contentTypes.allSatisfy { contentType in
            restrictedHeaders.allSatisfy { !contentType.lowercased().contains($0) }
        }
    }
}
