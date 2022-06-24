//
//  Pioneer+Http.swift
//  Pioneer
//
//  Created by d-exclaimation on 11:34 AM.
//

import Foundation
import Vapor
import GraphQL

extension Pioneer {
    /// Apply middleware for `POST`
    func applyPost(
        on router: RoutesBuilder,
        at path: PathComponent = "graphql",
        with bodyStreamStrategy: HTTPBodyStreamStrategy = .collect,
        allowing: [OperationType]
    ) {
        func handler(req: Request) async throws -> Response {
            let gql = try req.content.decode(GraphQLRequest.self)
            return try await handle(req: req, from: gql, allowing: allowing)
        }
        router.on(.POST, path, body: bodyStreamStrategy, use: handler(req:))
    }

    /// Apply middleware for `GEt`
    func applyGet(on router: RoutesBuilder, at path: PathComponent = "graphql", csrf: Bool = false, allowing: [OperationType]) {
        func handler(req: Request) async throws -> Response {
            // Query is most important and should always be there, otherwise reject request
            guard let query: String = req.query[String.self, at: "query"] else {
                throw GraphQLError(ResolveError.unableToParseQuery)
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
    
    func csrfProtected(req: Request) async -> Bool {
        let restrictedHeaders = ["text/plain", "application/x-www-form-urlencoded", "multipart/form-data"]
        if !req.headers["Apollo-Require-Preflight"].isEmpty || !req.headers["X-Apollo-Operation-Name"].isEmpty {
            return true
        }
        for contentType in req.headers[.contentType] {
            for header in restrictedHeaders {
                if contentType.contains(header) {
                    return false
                }
            }
        }
        return true
    }
}
