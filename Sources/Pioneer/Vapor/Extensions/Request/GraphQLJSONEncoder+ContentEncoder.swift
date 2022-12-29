//
//  GraphQLJSONEncoder+ContentEncoder.swift
//  pioneer
//
//  Created by d-exclaimation on 11:30.
//

import class GraphQL.GraphQLJSONEncoder
import Vapor

extension GraphQLJSONEncoder: ContentEncoder {
    public func encode<E>(_ encodable: E, to body: inout NIOCore.ByteBuffer, headers: inout NIOHTTP1.HTTPHeaders) throws where E: Encodable {
        headers.contentType = .json
        try body.writeBytes(self.encode(encodable))
    }
}
