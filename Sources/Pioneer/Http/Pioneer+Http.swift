//
//  Pioneer+Http.swift
//  Pioneer
//
//  Created by d-exclaimation on 11:34 AM.
//  Copyright © 2021 d-exclaimation. All rights reserved.
//

import Foundation
import Vapor
import GraphQL

extension Pioneer {
    /// Apply middleware for `POST`
    func applyPost(on router: RoutesBuilder, at path: PathComponent = "graphql", allowing: [OperationType]) {
        func handler(req: Request) async throws -> Response {
            let gql = try req.content.decode(GraphQLRequest.self)
            return try await handle(req: req, from: gql, allowing: allowing)
        }
        router.post(path, use: handler(req:))
    }

    /// Apply middleware for `GEt`
    func applyGet(on router: RoutesBuilder, at path: PathComponent = "graphql", allowing: [OperationType]) {
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

}