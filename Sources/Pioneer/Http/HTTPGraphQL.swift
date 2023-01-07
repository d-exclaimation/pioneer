//
//  GraphQLResponse.swift
//  pioneer
//
//  Created by d-exclaimation on 22:16.
//

import struct GraphQL.GraphQLError
import struct GraphQL.GraphQLResult
import enum GraphQL.Map
import struct NIOHTTP1.HTTPHeaders
import enum NIOHTTP1.HTTPMethod
import enum NIOHTTP1.HTTPResponseStatus

/// HTTP-based GraphQL Response
public struct HTTPGraphQLResponse: @unchecked Sendable {
    /// GraphQL Result for this response
    public var result: GraphQLResult

    /// HTTP status code for this response
    public var status: HTTPResponseStatus

    /// Any additional HTTP headers for this response
    public var headers: HTTPHeaders?

    public init(result: GraphQLResult, status: HTTPResponseStatus, headers: HTTPHeaders? = nil) {
        self.result = result
        self.status = status
        self.headers = headers
    }

    public init(data: Map? = nil, errors: [GraphQLError] = [], status: HTTPResponseStatus, headers: HTTPHeaders? = nil) {
        self.result = .init(data: data, errors: errors)
        self.status = status
        self.headers = headers
    }
}

/// HTTP-based GraphQL request
public struct HTTPGraphQLRequest: Sendable {
    /// GraphQL Request for this request
    public var request: GraphQLRequest

    /// HTTP headers given in this request
    public var headers: HTTPHeaders

    /// HTTP method for this request
    public var method: HTTPMethod

    public init(request: GraphQLRequest, headers: HTTPHeaders, method: HTTPMethod) {
        self.request = request
        self.headers = headers
        self.method = method
    }

    public init(
        query: String,
        operationName: String? = nil,
        variables: [String: Map]? = nil,
        headers: HTTPHeaders,
        method: HTTPMethod
    ) {
        self.request = .init(query: query, operationName: operationName, variables: variables)
        self.headers = headers
        self.method = method
    }

    /// Is request accepting GraphQL media type
    public var isAcceptingGraphQLResponse: Bool {
        self.headers[.accept].contains(HTTPGraphQLRequest.mediaType)
    }

    /// GraphQL over HTTP spec's accept media type
    public static var mediaType = "application/graphql-response+json"

    /// GraphQL over HTTP spec's content type
    public static var contentType = "\(mediaType); charset=utf-8, \(mediaType)"

    /// Known possible failure in converting HTTP into GraphQL over HTTP request
    public enum Issue: Error, Sendable {
        case invalidMethod
        case invalidContentType
    }
}

/// A type that can be transformed into GraphQLRequest and HTTPGraphQLRequest
public protocol GraphQLRequestConvertible {
    /// HTTP headers given in this request
    var headers: HTTPHeaders { get }

    /// HTTP method for this request
    var method: HTTPMethod { get }

    /// Decode / parse body into a specific decodable type
    /// - Parameter decodable: Decodable type
    /// - Returns: Parsed body
    func body<T: Decodable>(_ decodable: T.Type) throws -> T

    /// Decode with a specific key name if possible from URL Query / Search Parameters
    /// - Parameters:
    ///   - decodable: Decodable type
    ///   - at: Name of field to decode
    /// - Returns: The parsed payload if possible, otherwise nil
    func urlQuery<T: Decodable>(_ decodable: T.Type, at: String) -> T?
}

public extension GraphQLRequestConvertible {
    /// GraphQLRequest from this type
    var graphql: GraphQLRequest {
        get throws {
            switch method {
            case .GET:
                guard let query = urlQuery(String.self, at: "query") else {
                    throw GraphQLRequest.ParsingIssue.missingQuery
                }
                let variables: [String: Map]? = self.urlQuery(String.self, at: "variables")
                    .flatMap { $0.data(using: .utf8)?.to([String: Map].self) }
                let operationName: String? = self.urlQuery(String.self, at: "operationName")
                return GraphQLRequest(query: query, operationName: operationName, variables: variables)
            case .POST:
                guard !headers[.contentType].isEmpty else {
                    throw HTTPGraphQLRequest.Issue.invalidContentType
                }
                return try body(GraphQLRequest.self)
            default:
                throw HTTPGraphQLRequest.Issue.invalidMethod
            }
        }
    }

    /// HTTPGraphQLRequest from this type
    var httpGraphQL: HTTPGraphQLRequest {
        get throws {
            try .init(request: graphql, headers: headers, method: method)
        }
    }
}
