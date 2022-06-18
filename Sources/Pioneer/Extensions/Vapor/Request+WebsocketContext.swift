//  Request+WebsocketContext.swift
//  
//
//  Created by d-exclaimation on 18/06/22.
//

import Foundation
import NIO
import Vapor

public extension Request {
    /// Default websocket context builder from the request, connection params, and graphql request
    /// - Parameters:
    ///   - payload: The connection parameters payload
    ///   - gql: The graphql request for the operation
    ///   - contextBuilder: The HTTP context builder
    /// - Returns: The context from the builder
    func defaultWebsocketContextBuilder<Context>(
        payload: ConnectionParams,
        gql: GraphQLRequest,
        contextBuilder: @escaping @Sendable (Request, Response) async throws -> Context
    ) async throws -> Context  {
        let uri = URI(
            scheme: url.scheme,
            host: url.host,
            port: url.port,
            path: url.path,
            query: "\(url.query ?? "")\(url.query.isSome ? "&" : "")\(payload.queries)",
            fragment: url.fragment
        )
        let req = Request(
            application: application,
            method: .POST,
            url: uri,
            headers: payload.headers,
            on: eventLoop
        )
        try req.content.encode(gql)
        let res = Response()
        return try await contextBuilder(req, res)
    }
}

extension GraphQLRequest: Content {}

public extension ConnectionParams {
    /// Query string from the connection parameter
    var queries: String {
        guard let payload = self else { return "" }
        guard let query = payload["query"] ?? payload["queries"] ?? payload["queryParams"] ?? payload["queryParameters"] else { return "" }
        switch query {
        // Single string query variables in form of "key1=value1&key2=value2"
        case .string(let str):
            return str.contains("=") ? str : ""
        // Multiple list of query string in form of ["key=value", ...]
        case .array(let strings):
            return strings
                .compactMap {
                    guard case .string(let str) = $0 else {
                        return nil
                    }
                    return str.contains("=") ? str : nil
                }
                .joined(separator: "&")
        // Multiple query strings in form of ["key": "value", ...]
        case .dictionary(let queries):
            return queries
                .map { key, val in
                    guard case .string(let value) = val else {
                        return "\(key)=\(val.jsonString)"
                    }
                    return "\(key)=\(value)"
                }
                .joined(separator: "&")
        default:
            return ""
        }
    }
    
    /// HTTPHeaaders from connection parameter
    var headers: HTTPHeaders {
        guard let payload = self else { return .init() }
        guard case .dictionary(let headerDict) = payload["header"] ?? payload["headers"] else { return .init() }
        return .init(headerDict.map { (key, val) in
            guard case .string(let value) = val else {
                return (key, val.jsonString)
            }
            return (key, value)
        })
    }
}


extension Optional {
    /// Check if the optional is not empty
    var isSome: Bool {
        if case .none = self {
            return false
        }
        return true
    }
}
