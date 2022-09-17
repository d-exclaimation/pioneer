//
//  Probe.swift
//  Pioneer
//
//  Created by d-exclaimation on 11:32 PM.
//

import GraphQL
import class Graphiti.Schema
import class Vapor.Request
import struct Foundation.UUID
import protocol NIO.EventLoopGroup

extension Pioneer {
    /// Actor for handling Websocket distribution and dispatching of client specific actor
    actor Probe {
        private let schema: GraphQLSchema
        private let resolver: Resolver
        private let proto: SubProtocol.Type
        private let websocketContextBuilder: @Sendable (Request, ConnectionParams, GraphQLRequest) async throws -> Context
        private let websocketOnInit: @Sendable (ConnectionParams) async throws -> Void

        init(
            schema: GraphQLSchema, resolver: Resolver, proto: SubProtocol.Type,
            websocketContextBuilder: @Sendable @escaping (Request, ConnectionParams, GraphQLRequest) async throws -> Context,
            websocketOnInit: @Sendable @escaping (ConnectionParams) async throws -> Void = { _ in }
        ) {
            self.schema = schema
            self.resolver = resolver
            self.proto = proto
            self.websocketContextBuilder = websocketContextBuilder
            self.websocketOnInit = websocketOnInit
        }
        
        init(
            schema: Schema<Resolver, Context>, resolver: Resolver, proto: SubProtocol.Type,
            websocketContextBuilder: @Sendable @escaping (Request, ConnectionParams, GraphQLRequest) async throws -> Context,
            websocketOnInit: @Sendable @escaping (ConnectionParams) async throws -> Void = { _ in }
        ) {
            self.schema = schema.schema
            self.resolver = resolver
            self.proto = proto
            self.websocketContextBuilder = websocketContextBuilder
            self.websocketOnInit = websocketOnInit
        }

        // MARK: - Private mutable states
        private var clients: [UUID: Process] = [:]
        private var drones: [UUID: Drone] = [:]
        
        
        // MARK: - Event callbacks
        
        /// Allocate space and save any verified process
        func connect(with process: Process) async {
            do {
                try await websocketOnInit(process.payload)
                clients.update(process.id, with: process)
            } catch {
                await deny(process: process, with: error)
            }
        }
        
        /// Deallocate the space from a closing process
        func disconnect(for pid: UUID) async {
            await drones[pid]?.acid()
            clients.delete(pid)
            drones.delete(pid)
        }
        
        /// Long running operation require its own actor, thus initialing one if there were none prior
        func start(for pid: UUID, with oid: String, given gql: GraphQLRequest) async {
            guard let process = clients[pid] else { 
                await deny(process: process, with: error)
                return
            }

            let drone = drones.getOrElse(pid) {
                .init(process,
                    schema: schema,
                    resolver: resolver,
                    proto: proto,
                    websocketContextBuilder: websocketContextBuilder
                )
            }
            drones.update(pid, with: drone)
            await drone.start(for: oid, given: gql)
        }
        
        /// Short lived operation is processed immediately and pipe back later
        func once(for pid: UUID, with oid: String, given gql: GraphQLRequest) async {
            guard let process = clients[pid] else { 
                await deny(process: process, with: error)
                return
            }

            let future = execute(gql, payload: process.payload, req: process.req)
            
            pipeToSelf(future: future) { sink, res in
                switch res {
                case .success(let value):
                    await sink.outgoing(
                        with: oid,
                        to: process,
                        given: .from(type: self.proto.next, id: oid, value)
                    )
                case .failure(let error):
                    let result: GraphQLResult = .init(data: nil, errors: [error.graphql])
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
    
        /// Build context and execute short-lived GraphQL Operation inside an event loop 
        private func execute(_ gql: GraphQLRequest, payload: ConnectionParams, req: Request) -> Future<GraphQLResult> {
            req.eventLoop.performWithTask { [unowned self] in
                let ctx = try await self.websocketContextBuilder(req, payload, gql)
                return try await self.executeOperation(for: gql, with: ctx, using: req.eventLoop)
            }
        }

        /// Execute short-lived GraphQL Operation
        private func executeOperation(for gql: GraphQLRequest, with ctx: Context, using eventLoop: EventLoopGroup) async throws -> GraphQLResult {
            try await executeGraphQL(
                schema: self.schema,
                request: gql.query,
                resolver: self.resolver,
                context: ctx,
                eventLoopGroup: eventLoop,
                variables: gql.variables,
                operationName: gql.operationName
            ) 
        }

        private func deny(process: Process, with error: Error) async {
            let err = GraphQLMessage.errors(type: proto.error, [error.graphql])
            process.send(err.jsonString)
            process.keepAlive?.cancel()
            await process.close(code: .policyViolation) 
        } 
    }
}
