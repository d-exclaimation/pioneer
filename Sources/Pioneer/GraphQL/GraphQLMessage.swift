//
//  GraphQLMessage.swift
//  Pioneer
//
//  Created by d-exclaimation on 10:48 AM.
//

import Foundation
import GraphQL

/// GraphQL Websocket Message according to all sub-protocol
public struct GraphQLMessage: Codable {
    /// Operation based ID if any
    public var id: String?
    /// Message type specified to allow differentiation
    public var type: String
    /// Any payload in terms of object form
    public var payload: [String: Map]?

    init(id: String? = nil, type: String, payload: [String: Map]? = nil) {
        self.id = id
        self.type = type
        self.payload = payload
    }

    /// Turn GraphQLResult into working GraphQLMessage
    static func from(type: String, id: String? = nil, _ gql: GraphQL.GraphQLResult) -> GraphQLMessage {
        let errors = parseError(gql.errors)
        switch (gql.data, errors) {
        case (.some(let data), .some(let errors)):
            return .init(id: id, type: type, payload: ["data": data, "errors": errors])
        case (.some(let data), .none):
            return .init(id: id, type: type, payload: ["data": data])
        case (.none, .some(let errors)):
            return .init(id: id, type: type, payload: ["errors": errors])
        case (.none, .none):
            return .init(id: id, type: type)
        }
    }

    private static func parseError(_ err: [GraphQLError]) -> Map? {
        guard let data = try? JSONEncoder().encode(err) else { return .none }
        return data.to(Map.self)
    }

    /// Variant type to escape constraint on payload, use only for cases where certain payload break the object spec
    public struct Variance: Codable {
        public var id: String?
        public var type: String
        public var payload: Map?

        init(id: String? = nil, type: String, payload: Map? = nil) {
            self.id = id
            self.type = type
            self.payload = payload
        }
    }

    static func errors(id: String? = nil, type: String, _ error: [GraphQLError]) -> Variance {
        let err = error
            .map { $0.message }
            .map { msg -> Map in ["message": Map.string(msg)] }
        return GraphQLMessage.Variance(
            id: id,
            type: type,
            payload: .array(err)
        )
    }
}

extension Encodable {
    /// Any encodable into Data if possible
    var json: Data? {
        try? GraphQLJSONEncoder().encode(self)
    }

    /// Any encodable into JSON String otherwise null is returned
    var jsonString: String {
        json.flatMap { String(data: $0, encoding: .utf8)} ?? "null"
    }
}
