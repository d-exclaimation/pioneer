//
//  GraphQLMessage.swift
//  Pioneer
//
//  Created by d-exclaimation on 10:48 AM.
//  Copyright © 2021 d-exclaimation. All rights reserved.
//

import Foundation
import GraphQL

public struct GraphQLMessage: Codable {
    public var id: String?
    public var type: String
    public var payload: [String: Map]?

    init(id: String? = nil, type: String, payload: [String: Map]? = nil) {
        self.id = id
        self.type = type
        self.payload = payload
    }

    static func from(type: String, id: String? = nil, _ gql: GraphQLResult) -> GraphQLMessage {
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
        return try? JSONDecoder().decode(Map.self, from: data)
    }

    public struct Variance: Codable {
        public var id: String?
        public var type: String
        public var payload: Map?
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
    var json: Data? {
        try? JSONEncoder().encode(self)
    }

    var jsonString: String {
        json.flatMap { String(data: $0, encoding: .utf8)} ?? "{}"
    }
}
