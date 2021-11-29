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


    enum Act {
        case connect(pid: UUID, ws: WebSocket)
        case disconnect(pid: UUID)
        case start(pid: UUID, oid: String, query: String, ctx: Context, vars: [String:Map], op: String?)
        case once(pid: UUID, oid: String, query: String, ctx: Context, vars: [String:Map], op: String?)
        case stop(pid: UUID, oid: String)
        // TODO: Change `res` to a Subprotocol message
        case outgoing(oid: String, ws: WebSocket, res: GraphQLResult)
        // TODO: Change `res` to a Subprotocol message
        case error(ws: WebSocket, res: GraphQLResult)
    }
}