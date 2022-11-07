//
//  GraphQLResponse.swift
//  pioneer
//
//  Created by d-exclaimation on 22:16.
//

import enum NIOHTTP1.HTTPResponseStatus
import enum NIOHTTP1.HTTPMethod
import struct NIOHTTP1.HTTPHeaders
import struct GraphQL.GraphQLResult

extension Pioneer {
    /// HTTP-based GraphQL Response
    public struct HTTPGraphQLResponse {
        /// GraphQL Result for this response
        public var result: GraphQLResult

        /// HTTP status code for this response
        public var status: HTTPResponseStatus
    }

    /// HTTP-based GraphQL request
    public struct HTTPGraphQLRequest {
        /// GraphQL Request for this request
        public var request: GraphQLRequest

        /// HTTP headers given in this request 
        public var headers: HTTPHeaders

        /// HTTP method for this request
        public var method: HTTPMethod
    }
}