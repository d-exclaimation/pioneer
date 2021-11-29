//
//  Pioneer+Action.swift
//  Pioneer
//
//  Created by d-exclaimation on 10:41 AM.
//  Copyright © 2021 d-exclaimation. All rights reserved.
//

import Foundation
import Vapor
import GraphQL

extension Pioneer {
    enum Intent {
        case initial, ping, terminate, ignore
        case start(oid: String, query: String, op: String?, vars: [String:Map])
        case once(oid: String, query: String, op: String?, vars: [String:Map])
        case stop(oid: String)
        case error(oid: String, message: String)
        case fatal(message: String)
    }
}