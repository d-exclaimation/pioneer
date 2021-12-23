//
//  Drone.swift
//  Pioneer
//
//  Created by d-exclaimation on 4:55 PM.
//

import Foundation
import Desolate
import Vapor
import GraphQL
import Graphiti

extension Pioneer {
    /// Drone acting as concurrent safe actor for each client managing operations and subscriptions
    actor Drone: AbstractDesolate {
        private let process: Process
        private let schema: GraphQLSchema
        private let resolver: Resolver
        private let proto: SubProtocol.Type

        init(_ process: Process, schema: GraphQLSchema, resolver: Resolver, proto: SubProtocol.Type) {
            self.schema = schema
            self.resolver = resolver
            self.proto = proto
            self.process = process
        }

        init(_ process: Process, schema: Schema<Resolver, Context>, resolver: Resolver, proto: SubProtocol.Type) {
            self.schema = schema.schema
            self.resolver = resolver
            self.proto = proto
            self.process = process
        }

        // MARK: - Private mutable states
        var status: Signal = .running
        var tasks: [String: Deferred<Void>] = [:]

        func onMessage(msg: Act) async -> Signal {
            switch msg {
            case .start(oid: let oid, gql: let gql):
                await onStart(for: oid, given: gql)

            case .stop(oid: let oid):
                onStop(for: oid)

            case .ended(oid: let oid):
                onEnd(for: oid)

            case .output(oid: let oid, let message):
                onOutput(for: oid, given: message)
                
            case .acid:
                onTerminate()
                return .stopped
            }
            return .running
        }
        
        // MARK: - Event callbacks
        
        /// Start subscriptions, setup pipe pattern, and callbacks
        private func onStart(for oid: String, given gql: GraphQLRequest) async {
            let nextTypename = proto.next
            let subscriptionResult = await subscription(gql: gql)
            
            // Guard for getting the required subscriptions stream, if not send `next` with errors, and end subscription
            guard let subscription = subscriptionResult.stream else {
                let res = GraphQL.GraphQLResult(errors: subscriptionResult.errors)
                process.send(GraphQLMessage.from(type: proto.next, id: oid, res).jsonString)
                process.send(GraphQLMessage(id: oid, type: proto.complete).jsonString)
                return
            }
            
            // Guard for getting the async stream, if not sent `next` saying failure in convertion, and end subscription
            guard let asyncStream = subscription.asyncStream() else {
                let res = GraphQL.GraphQLResult(errors: [
                    .init(message: "Internal server error, failed to fetch AsyncStream")
                ])
                process.send(GraphQLMessage.from(type: proto.next, id: oid, res).jsonString)
                process.send(GraphQLMessage(id: oid, type: proto.complete).jsonString)
                return
            }


            // Transform async stream into messages and pipe back all messages into the Actor itself
            let task = asyncStream.pipe(
                to: self,
                complete: { sink in
                    await sink.onEnd(for: oid)
                },
                failure: { sink, _ in
                    await sink.onEnd(for: oid)
                },
                next: { sink, res in
                    await sink.onOutput(for: oid, given: .from(type: nextTypename, id: oid, res))
                }
            )
            tasks.update(oid, with: task)
        }
        
        /// Stop subscription, shutdown nozzle and remove it so preventing overflow of any messages
        private func onStop(for oid: String) {
            guard let task = tasks[oid] else { return }

            tasks.delete(oid)
            task.cancel()
        }
        
        /// Send an ending message
        /// but prevent completion message if nozzle doesn't exist
        /// e.g: - Shutdown-ed operation
        private func onEnd(for oid: String) {
            guard tasks.has(oid) else { return }
            tasks.delete(oid)
            let message = GraphQLMessage(id: oid, type: proto.complete)
            process.send(message.jsonString)
        }
        
        /// Push message to websocket connection
        /// but prevent completion message if nozzle doesn't exist
        /// e.g: - Shutdown-ed operation
        private func onOutput(for oid: String, given msg: GraphQLMessage) {
            guard tasks.has(oid) else { return }
            process.send(msg.jsonString)
        }
        
        /// Kill actor by cancelling and deallocating all stored task
        private func onTerminate() {
            tasks.values.forEach { $0.cancel() }
            tasks.removeAll()
        }
        
        // MARK: - Utility methods

        /// Execute subscription from GraphQL Resolver and Schema, await the future value and catch error into a SubscriptionResult
        private func subscription(gql: GraphQLRequest) async -> SubscriptionResult {
            do {
                return try await subscribeGraphQL(
                    schema: schema,
                    request: gql.query,
                    resolver: resolver,
                    context: process.ctx,
                    eventLoopGroup: process.req.eventLoop,
                    variables: gql.variables,
                    operationName: gql.operationName
                )
            } catch {
                return .init(
                    stream: nil,
                    errors: [.init(error)]
                )
            }
        }

        deinit {
            tasks.forEach { (oid, task) in
                let message = GraphQLMessage(id: oid, type: proto.complete)
                process.send(message.jsonString)
                task.cancel()
            }
        }
        
        enum Act {
            case start(oid: String, gql: GraphQLRequest)
            case stop(oid: String)
            case ended(oid: String)
            case output(oid: String, GraphQLMessage)
            case acid
        }
    }
}
