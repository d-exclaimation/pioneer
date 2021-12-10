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

    /// Apply playground for `GET` on `/playground`.
    func applyPlayground(on router: RoutesBuilder, at path: PathComponent) {
        let graphqlPlayground = """
        <!DOCTYPE html>
        <html>

        <head>
            <meta charset=utf-8/>
            <meta name="viewport"
                  content="user-scalable=no, initial-scale=1.0, minimum-scale=1.0, maximum-scale=1.0, minimal-ui">
            <title>GraphQL Playground</title>
            <link rel="stylesheet" href="//cdn.jsdelivr.net/npm/graphql-playground-react/build/static/css/index.css"/>
            <link rel="shortcut icon" href="//cdn.jsdelivr.net/npm/graphql-playground-react/build/favicon.png"/>
            <script src="//cdn.jsdelivr.net/npm/graphql-playground-react/build/static/js/middleware.js"></script>
        </head>

        <body>
        <div id="root">
            <style>
                body {
                    background-color: rgb(23, 42, 58);
                    font-family: Open Sans, sans-serif;
                    height: 90vh;
                }

                #root {
                    height: 100%;
                    width: 100%;
                    display: flex;
                    align-items: center;
                    justify-content: center;
                }

                .loading {
                    font-size: 32px;
                    font-weight: 200;
                    color: rgba(255, 255, 255, .6);
                    margin-left: 20px;
                }

                img {
                    width: 78px;
                    height: 78px;
                }

                .title {
                    font-weight: 400;
                }
            </style>
            <img src='//cdn.jsdelivr.net/npm/graphql-playground-react/build/logo.png' alt=''>
            <div class="loading"> Loading
                <span class="title">GraphQL Playground</span>
            </div>
        </div>
        <script>window.addEventListener('load', function (event) {
            GraphQLPlayground.init(document.getElementById('root'), {
                endpoint: "/\(path)",
                subscriptionEndpoint: "/\(path)/websocket"
            })
        })</script>
        </body>

        </html>
        """
        
        func handler(req: Request) -> Response {
            Response(
                status: .ok,
                headers: HTTPHeaders([(HTTPHeaders.Name.contentType.description, "text/html")]),
                body: Response.Body(string: graphqlPlayground)
            )
        }
        
        router.get("playground", use: handler)
    }
}
