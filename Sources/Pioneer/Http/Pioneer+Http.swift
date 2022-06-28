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

extension Pioneer {
    /// Apply middleware for `POST`
    func applyPost(
        on router: RoutesBuilder,
        at path: PathComponent = "graphql",
        csrf: Bool = false,
        bodyStrategy: HTTPBodyStreamStrategy = .collect,
        allowing: [OperationType]
    ) {
        func handler(req: Request) async throws -> Response {
            // Check for CSRF Prevention
            guard isCSRFProtected(isActive: csrf, on: req) else {
                return try GraphQLError(
                    message: "Operation has been blocked as a potential Cross-Site Request Forgery (CSRF)." +
                    "Either specify a 'content-type' header that is not 'text/plain', 'application/x-www-form-urlencoded', or 'multipart/form-data' " +
                    " or provide a non-empty value for one of the following headers: 'x-apollo-operation-name' or 'apollo-require-preflight'")
                .response(with: .badRequest)
            }
            let gql = try req.content.decode(GraphQLRequest.self)
            return try await handle(req: req, from: gql, allowing: allowing)
        }
        router.on(.POST, path, body: bodyStrategy, use: handler(req:))
    }

    /// Apply middleware for `GET`
    func applyGet(
        on router: RoutesBuilder,
        at path: PathComponent = "graphql",
        csrf: Bool = false,
        allowing: [OperationType]
    ) {
        func handler(req: Request) async throws -> Response {
            // Check for CSRF Prevention
            guard isCSRFProtected(isActive: csrf, on: req) else {
                return try GraphQLError(
                    message: "Operation has been blocked as a potential Cross-Site Request Forgery (CSRF)." +
                    "Either specify a 'content-type' header that is not 'text/plain', 'application/x-www-form-urlencoded', or 'multipart/form-data' " +
                    " or provide a non-empty value for one of the following headers: 'x-apollo-operation-name' or 'apollo-require-preflight'"
                )
                .response(with: .badRequest)
            }
            
            // Query is most important and should always be there, otherwise reject request
            guard let query: String = req.query[String.self, at: "query"] else {
                return try GraphQLError(
                    message: "Unable to parse query and identify operation. Specify the 'query' query string parameter with the GraphQL query."
                )
                .response(with: .badRequest)
            }
            let variables: [String: Map]? = (req.query[String.self, at: "variables"])
                .flatMap { (str: String) -> [String: Map]? in
                    str.data(using: .utf8)?.to([String: Map].self)
                }
            let operationName: String? = req.query[String.self, at: "operationName"]
            let gql = GraphQLRequest(query: query, operationName: operationName, variables: variables)

            return try await handle(req: req, from: gql, allowing: allowing)
        }
        router.get(path, use: handler(req:))
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
