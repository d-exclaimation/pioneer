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
        bodyStrategy: HTTPBodyStreamStrategy = .collect
    ) {
        router.on(.POST, path, body: bodyStrategy, use: httpHandler)
    }

    /// Apply middleware for `GET`
    func applyGet(
        on router: RoutesBuilder,
        at path: PathComponent = "graphql"
    ) {
        router.get(path, use: httpHandler)
    }

    /// Common Handler for GraphQL through HTTP
    /// - Parameter req: The HTTP request being made
    /// - Returns: A response from the GraphQL operation execution properly formatted
    func httpHandler(req: Request) async throws -> Response {
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
            return try await handle(req: req, from: gql, allowing: httpStrategy.allowed(for: req.method))
        } catch let error as Abort {
            return try GraphQLError(message: error.reason).response(with: error.status)
        } catch {
            return try error.graphql.response(with: .internalServerError)
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
