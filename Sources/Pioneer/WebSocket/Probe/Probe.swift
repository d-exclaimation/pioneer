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
    /// Actor for handling Websocket distribution and dispatching of client specific actor
    actor Probe: AbstractDesolate, NonStop {
        private let schema: GraphQLSchema
        private let resolver: Resolver
        private let proto: SubProtocol.Type

        init(schema: GraphQLSchema, resolver: Resolver, proto: SubProtocol.Type) {
            self.schema = schema
            self.resolver = resolver
            self.proto = proto
        }
        
        init(schema: Schema<Resolver, Context>, resolver: Resolver, proto: SubProtocol.Type) {
            self.schema = schema.schema
            self.resolver = resolver
            self.proto = proto
        }

        // Mark: -- States --
        private var clients: [UUID: Process] = [:]
        private var drones: [UUID: Desolate<Drone>] = [:]

        func onMessage(msg: Act) async -> Signal {
            switch msg {
            // Allocate space and save any verified process
            case .connect(process: let process):
                clients.update(process.id, with: process)

            // Deallocate the space from a closing process
            case .disconnect(pid: let pid):
                await drones[pid]?.task(with: .acid)
                clients.delete(pid)
                drones.delete(pid)

            // Long running operation require its own actor, thus initialing one if there were none prior
            case .start(pid: let pid, oid: let oid, gql: let gql):
                guard let process = clients[pid] else { break }
                let drone = drones.getOrElse(pid) {
                    spawn(.init(process,
                        schema: schema,
                        resolver: resolver,
                        proto: proto
                    ))
                }
                await drone.task(with: .start(oid: oid, gql: gql))
                drones.update(pid, with: drone)

            // Short lived operation is processed immediately and pipe back later
            case .once(pid: let pid, oid: let oid, gql: let gql):
                guard let process = clients[pid] else { break }

                let future = execute(gql, ctx: process.ctx, req: process.req)

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

            // Stopping any operation to client specific actor
            case .stop(pid: let pid, oid: let oid):
                await drones[pid]?.task(with: .stop(oid: oid))

            // Message from pipe to self result after processing short lived operation
            case .outgoing(oid: let oid, process: let process, res: let res):
                process.send(res.jsonString)
                process.send(GraphQLMessage(id: oid, type: proto.complete).jsonString)
            }

            return same
        }

        /// Execute short-lived GraphQL Operation
        private func execute(_ gql: GraphQLRequest, ctx: Context, req: Request) -> Future<GraphQLResult> {
            do {
                return try graphql(
                    schema: schema,
                    request: gql.query,
                    rootValue: resolver,
                    context: ctx,
                    eventLoopGroup: req.eventLoop,
                    variableValues: gql.variables ?? [:],
                    operationName: gql.operationName
                )
            } catch {
                return req.eventLoop.next().makeFailedFuture(error)
            }
        }

        enum Act {
            case connect(process: Process)
            case disconnect(pid: UUID)
            case start(pid: UUID, oid: String, gql: GraphQLRequest)
            case once(pid: UUID, oid: String, gql: GraphQLRequest)
            case stop(pid: UUID, oid: String)
            case outgoing(oid: String, process: Process, res: GraphQLMessage)
        }
    }
}
