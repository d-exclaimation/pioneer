//
//  GraphQLRequest.swift
//  GraphQLAsyncSequence
//
//  Created by d-exclaimation on 12:49 AM.
//  Copyright © 2021 d-exclaimation. All rights reserved.
//

import Foundation
import GraphQL

public struct GraphQLRequest: Codable {
    public var query: String
    public var operationName: String?
    public var variables: [String: Map]?
}
