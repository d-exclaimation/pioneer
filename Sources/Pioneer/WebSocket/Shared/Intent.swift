//
//  Pioneer+Action.swift
//  Pioneer
//
//  Created by d-exclaimation on 10:41 AM.
//

import enum GraphQL.Map

extension Pioneer {
    /// Pioneer GraphQL message Intention to static differentiate GraphQL Message types
    enum Intent {
        case initial(payload: [String: Map]?)
        case ping, terminate, ignore
        case start(oid: String, gql: GraphQLRequest)
        case once(oid: String, gql: GraphQLRequest)
        case stop(oid: String)
        case error(oid: String, message: String)
        case fatal(message: String)
    }
}
