//  Response+GraphQLError.swift
//  
//
//  Created by d-exclaimation on 25/06/22.
//

import Foundation
import Vapor
import GraphQL

extension GraphQLError {
    func response(with code: HTTPResponseStatus) throws -> Response {
        let response = Response(status: code)
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
}
