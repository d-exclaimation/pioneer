//
//  Probe.swift
//  Pioneer
//
//  Created by d-exclaimation on 11:32 PM.
//  Copyright © 2021 d-exclaimation. All rights reserved.
//

import Foundation
import Desolate
import Vapor
import GraphQL
import Graphiti

extension Pioneer {
    actor Probe: AbstractDesolate, NonStop {
        private let schema: Schema<Resolver, Context>
        private let resolver: Resolver
        private let proto: SubProtocol.Type

        init(schema: Schema<Resolver, Context>, resolver: Resolver, proto: SubProtocol.Type) {
            self.schema = schema
            self.resolver = resolver
            self.proto = proto
        }

        // States
        private var clients: [UUID: Process] = [:]

        func onMessage(msg: Act) async -> Signal {
            switch msg {
            case .connect(process: let process):
                clients.update(process.id, with: process)

            case .disconnect(pid: let pid):
                clients.delete(pid)

            case .start(pid: let pid, oid: let oid, gql: let gql, ctx: let ctx):
                // TODO: Start long running process
                break

            case .once(pid: let pid, oid: let oid, gql: let gql, ctx: let ctx):
                guard let process = clients[pid] else { break }

                let future = execute(gql, ctx: ctx, req: process.req)

                pipeToSelf(future: future) { res in
                    switch res {
                    case .success(let result):
                        return .outgoing(oid: oid, process: process,
                            res: .from(type: self.proto.next, id: oid, result)
                        )
                    case .failure(let error):
                        let result: GraphQLResult = .init(data: nil, errors: [.init(message: error.localizedDescription)])
                        return .outgoing(oid: oid, process: process,
                            res: .from(type: self.proto.next, id: oid, result)
                        )
                    }
                }

            case .stop(pid: let pid, oid: let oid):
                // TODO: Stop running process for pid and oid
                break

            case .outgoing(oid: let oid, process: let process, res: let res):
                process.send(res.jsonString)
                process.send(GraphQLMessage(id: oid, type: proto.complete).jsonString)
            }
            return same
        }

        private func execute(_ gql: GraphQLRequest, ctx: Context, req: Request) -> Future<GraphQLResult> {
            schema.execute(
                request: gql.query,
                resolver: resolver,
                context: ctx,
                eventLoopGroup: req.eventLoop,
                variables: gql.variables ?? [:],
                operationName: gql.operationName
            )
        }

        enum Act {
            case connect(process: Process)
            case disconnect(pid: UUID)
            case start(pid: UUID, oid: String, gql: GraphQLRequest, ctx: Context)
            case once(pid: UUID, oid: String, gql: GraphQLRequest, ctx: Context)
            case stop(pid: UUID, oid: String)
            case outgoing(oid: String, process: Process, res: GraphQLMessage)
        }
    }
}
