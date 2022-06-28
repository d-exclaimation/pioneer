//
//  BuiltinTypes.swift
//  pioneer-integration-test
//
//  Created by d-exclaimation on 3:59 PM.
//

import Foundation
import GraphQL
import Graphiti

public typealias NoArgs = NoArguments

/// The ID scalar type represents a unique identifier, often used to refetch an object or as the key for a cache.
///
/// The ID type is serialized in the same way as a String; however, defining it as an ID signifies that it is not intended to be human‐readable.
public struct ID : Codable, ExpressibleByStringLiteral, CustomStringConvertible, Hashable, Sendable {
    /// Inner string properties
    public var id: String

    public init(_ id: String) {
        self.id = id
    }

    public init(stringLiteral value: String) {
        id = value
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        id = try container.decode(String.self)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(id)
    }

    public var description: String { id }

    /// Apply scalar to Graphiti schema to allow the use of ID.
    public static func asScalar<Resolver, Context>() -> Scalar<Resolver, Context, Self> {
        .init(ID.self, as: "ID")
            .description("The ID scalar type represents a unique identifier, often used to refetch an object or as the key for a cache. The ID type is serialized in the same way as a String; however, defining it as an ID signifies that it is not intended to be human‐readable")
    }

    /// Create a new ID from UUID
    public static func uuid() -> Self {
        .init(UUID().uuidString.lowercased())
    }

    /// Create a new ID from random letter
    public static func random(length: Int = 10) -> Self {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        let random = (0..<length).compactMap { _ in letters.randomElement() }
        return .init(.init(random))
    }

    /// Length of ID
    public var count: Int {
        id.count
    }
    
    /// String value of this ID type
    public var string: String {
        id
    }
}


public extension String {
    /// ID from this string
    var id: ID {
        .init(self)
    }
    
    /// ID from this string
    func toID() -> ID {
        .init(self)
    }
}

public extension UUID {
        /// ID from this string
    var id: ID {
        .init(self.uuidString)
    }
    
    /// ID from this string
    func toID() -> ID {
        .init(self.uuidString)
    }
}