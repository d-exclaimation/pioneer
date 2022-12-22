//
//  Map+Decoder.swift
//  pioneer
//
//  Created by d-exclaimation on 22:20.
//

import class Foundation.JSONEncoder
import class Foundation.JSONDecoder
import enum GraphQL.Map

public extension Map {
    /// Decode this map into a parseable value
    /// - Parameter dataType: The type to decode into
    /// - Returns: The decoded value
    func decode<T: Decodable>(_ dataType: T.Type) throws -> T {
        let data = try JSONEncoder().encode(self)
        return try JSONDecoder().decode(dataType, from: data)
    }
}

public extension Payload {
    /// Decode this payload into a parseable value
    /// - Parameter dataType: The type to decode into
    /// - Returns: The decoded value
    func decode<T: Decodable>(_ dataType: T.Type) throws -> T {
        let data = try JSONEncoder().encode(self)
        return try JSONDecoder().decode(dataType, from: data)
    }
}