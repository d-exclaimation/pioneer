//  Response+GraphQLError.swift
//
//
//  Created by d-exclaimation on 25/06/22.
//

import struct GraphQL.GraphQLError
import struct GraphQL.GraphQLResult
import struct NIOHTTP1.HTTPHeaders
import protocol Vapor.AbortError
import enum Vapor.HTTPResponseStatus
import class Vapor.Response

extension AbortError {
    func response(using response: Response) throws -> Response {
        try GraphQLError(message: reason).response(using: response, with: status, and: headers)
    }
}

extension GraphQLError {
    func response(with code: HTTPResponseStatus) throws -> Response {
        let response = Response(status: code)
        try response.content.encode(GraphQLResult(data: nil, errors: [self]))
        return response
    }

    func response(using response: Response, with code: HTTPResponseStatus, and headers: HTTPHeaders? = nil) throws -> Response {
        response.status = code
        if let headers = headers {
            response.headers.add(contentsOf: headers)
        }
        try response.content.encode(GraphQLResult(data: nil, errors: [self]))
        return response
    }

    func response(using response: Response) throws -> Response {
        if response.status == .ok {
            response.status = .internalServerError
        }
        try response.content.encode(GraphQLResult(data: nil, errors: [self]))
        return response
    }
}

extension Array where Element == GraphQLError {
    func response(with code: HTTPResponseStatus) throws -> Response {
        let response = Response(status: code)
        try response.content.encode(GraphQLResult(data: nil, errors: self))
        return response
    }

    func response(using response: Response) throws -> Response {
        try response.content.encode(GraphQLResult(data: nil, errors: self))
        return response
    }
}
