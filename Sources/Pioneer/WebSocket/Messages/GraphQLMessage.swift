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
}
