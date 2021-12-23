//
//  Probe.swift
//  Pioneer
//
//  Created by d-exclaimation on 11:32 PM.
//

import Foundation
import Vapor
import GraphQL
import Graphiti

extension Pioneer {
    /// Actor for handling Websocket distribution and dispatching of client specific actor
    actor Probe {
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

        // MARK: - Private mutable states
        private var clients: [UUID: Process] = [:]
        private var drones: [UUID: Drone] = [:]
        
        
        // MARK: - Event callbacks
        
        /// Allocate space and save any verified process
        func connect(with process: Process) async {
            clients.update(process.id, with: process)
        }
        
        /// Deallocate the space from a closing process
        func disconnect(for pid: UUID) async {
            await drones[pid]?.acid()
            clients.delete(pid)
            drones.delete(pid)
        }
        
        /// Long running operation require its own actor, thus initialing one if there were none prior
        func start(for pid: UUID, with oid: String, given gql: GraphQLRequest) async {
            guard let process = clients[pid] else { return }
            let drone = drones.getOrElse(pid) {
                .init(process,
                    schema: schema,
                    resolver: resolver,
                    proto: proto
                )
            }
            drones.update(pid, with: drone)
            await drone.start(for: oid, given: gql)
        }
        
        /// Short lived operation is processed immediately and pipe back later
        func once(for pid: UUID, with oid: String, given gql: GraphQLRequest) async {
            guard let process = clients[pid] else { return }

            let future = execute(gql, ctx: process.ctx, req: process.req)
            
            pipeToSelf(future: future) { sink, res in
                switch res {
                case .success(let value):
                    await sink.outgoing(
                        with: oid,
                        to: process,
                        given: .from(type: self.proto.next, id: oid, value)
                    )
                case .failure(let error):
                    let result: GraphQLResult = .init(data: nil, errors: [.init(message: error.localizedDescription)])
                    await sink.outgoing(
                        with: oid,
                        to: process,
                        given: .from(type: self.proto.next, id: oid, result)
                    )
                }
            }
        }

        /// Stopping any operation to client specific actor
        func stop(for pid: UUID, with oid: String) async {
            await drones[pid]?.stop(for: oid)
        }
        
        /// Message for pipe to self result after processing short lived operation
        func outgoing(with oid: String, to process: Process, given msg: GraphQLMessage) async {
            process.send(msg.jsonString)
            process.send(GraphQLMessage(id: oid, type: proto.complete).jsonString)
        }
        
        // MARK: - Utility methods
        
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
    }
}
