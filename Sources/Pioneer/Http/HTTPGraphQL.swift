//
//  GraphQLResponse.swift
//  pioneer
//
//  Created by d-exclaimation on 22:16.
//

import enum NIOHTTP1.HTTPResponseStatus
import enum NIOHTTP1.HTTPMethod
import enum GraphQL.Map
import struct NIOHTTP1.HTTPHeaders
import struct GraphQL.GraphQLResult
import struct GraphQL.GraphQLError

extension Pioneer {
    /// HTTP-based GraphQL Response
    public struct HTTPGraphQLResponse {
        /// GraphQL Result for this response
        public var result: GraphQLResult

        /// HTTP status code for this response
        public var status: HTTPResponseStatus

        public init(result: GraphQLResult, status: HTTPResponseStatus) {
            self.result = result
            self.status = status
        }

        public init(data: Map? = nil, errors: [GraphQLError] = [], status: HTTPResponseStatus) {
            self.result = .init(data: data, errors: errors)
            self.status = status
        }
    }

    /// HTTP-based GraphQL request
    public struct HTTPGraphQLRequest {
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
    }
}