//
//  Drone.swift
//  Pioneer
//
//  Created by d-exclaimation on 4:55 PM.
//  Copyright © 2021 d-exclaimation. All rights reserved.
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
        private let schema: Schema<Resolver, Context>
        private let resolver: Resolver
        private let proto: SubProtocol.Type

        init(_ process: Process, schema: Schema<Resolver, Context>, resolver: Resolver, proto: SubProtocol.Type) {
            self.schema = schema
            self.resolver = resolver
            self.proto = proto
            self.process = process
        }

        enum Act {
            case start(oid: String, gql: GraphQLRequest)
            case stop(oid: String)
            case ended(oid: String)
            case output(oid: String, GraphQLMessage)
            case acid
        }

        // Mark: -- States --
        var status: Signal = .running
        var tasks: [String: Deferred<Void>] = [:]

        func onMessage(msg: Act) async -> Signal {
            switch msg {
            // Start subscriptions, setup pipe pattern, and callbacks
            case .start(oid: let oid, gql: let gql):
                // Guards for getting all the required subscriptions stream
                guard let subscriptionResult = await subscription(gql: gql) else {
                    process.send(GraphQLMessage.errors(id: oid, type: proto.next, [.init(message: "Internal server error")]).jsonString)
                    break
                }
                guard let subscription = subscriptionResult.stream else {
                    let res = GraphQL.GraphQLResult(errors: subscriptionResult.errors)
                    process.send(GraphQLMessage.from(type: proto.next, id: oid, res).jsonString)
                    process.send(GraphQLMessage(id: oid, type: proto.complete).jsonString)
                    break
                }
                guard let asyncStream = subscription.asyncStream() else {
                    let res = GraphQL.GraphQLResult(errors: [.init(message: "Internal server error, failed to fetch AsyncStream")])
                    process.send(GraphQLMessage.from(type: proto.next, id: oid, res).jsonString)
                    process.send(GraphQLMessage(id: oid, type: proto.complete).jsonString)
                    break
                }

                let next = proto.next

                // Transform nozzle into flow and Pipe all messages into the Actor itself
                let task = asyncStream.pipeBack(to: oneself,
                    onComplete: {
                        .ended(oid: oid)
                    },
                    onFailure: { _ in
                        .ended(oid: oid)
                    },
                    transform: { res in
                        .output(oid: oid, GraphQLMessage.from(type: next, id: oid, res))
                    }
                )

                tasks.update(oid, with: task)

            // Stop subscription, shutdown nozzle and remove it so preventing overflow of any messages
            case .stop(oid: let oid):
                guard let task = tasks[oid] else { break }

                tasks.delete(oid)
                task.cancel()

            // Send an ending message
            // but prevent completion message if nozzle doesn't exist
            // e.g: - Shutdown-ed operation
            case .ended(oid: let oid):
                guard tasks.has(oid) else { break }
                let message = GraphQLMessage(id: oid, type: proto.complete)
                process.send(message.jsonString)

            // Push message to websocket connection
            // but prevent completion message if nozzle doesn't exist
            // e.g: - Shutdown-ed operation
            case .output(oid: let oid, let message):
                guard tasks.has(oid) else { break }
                process.send(message.jsonString)

            // Kill actor
            case .acid:
                tasks.values.forEach { $0.cancel() }
                tasks.removeAll()
                return .stopped
            }
            return .running
        }

        private func subscription(gql: GraphQLRequest) async -> SubscriptionResult? {
            try? await schema
                .subscribe(
                    request: gql.query,
                    resolver: resolver,
                    context: process.ctx,
                    eventLoopGroup: process.req.eventLoop,
                    variables: gql.variables ?? [:],
                    operationName: gql.operationName
                )
                .get()
        }

        deinit {
            tasks.forEach { (oid, task) in
                let message = GraphQLMessage(id: oid, type: proto.complete)
                process.send(message.jsonString)
                task.cancel()
            }
        }
    }
}
