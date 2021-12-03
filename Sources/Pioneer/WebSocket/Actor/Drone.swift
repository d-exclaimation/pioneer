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
        typealias GraphQLNozzle = Nozzle<Future<GraphQLResult>>

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
        var nozzles: [String: GraphQLNozzle] = [:]

        func onMessage(msg: Act) async -> Signal {
            switch msg {
            // Start subscriptions, setup pipe pattern, and callbacks
            case .start(oid: let oid, gql: let gql):
                // Guards for getting all the required subscriptions stream
                guard let subscriptionResult = await subscription(gql: gql) else { break }
                guard let subscription = subscriptionResult.stream else { break }
                guard let nozzle = subscription.nozzle() else { break }

                let next = proto.next
                nozzles.update(oid, with: nozzle)

                // Transform nozzle into flow
                let flow: AsyncCompactMapSequence<GraphQLNozzle, Act> =
                    nozzle.compactMap { (future: Future<GraphQLResult>) async -> Act? in
                        guard let res = try? await future.get() else { return nil }
                        return .output(oid: oid, .from(type: next, id: oid, res))
                    }

                // Pipe all messages into the Actor itself
                flow.pipe(to: oneself,
                    onComplete: {
                        .ended(oid: oid)
                    },
                    onFailure: { _ in
                        .ended(oid: oid)
                    }
                )
            // Stop subscription, shutdown nozzle and remove it so preventing overflow of any messages
            case .stop(oid: let oid):
                guard let nozzle = nozzles[oid] else { break }

                nozzles.delete(oid)
                nozzle.shutdown()

            // Send an ending message
            // but prevent completion message if nozzle doesn't exist
            // e.g: - Shutdown-ed operation
            case .ended(oid: let oid):
                guard nozzles.has(oid) else { break }
                let message = GraphQLMessage(id: oid, type: proto.complete)
                process.send(message.jsonString)

            // Push message to websocket connection
            // but prevent completion message if nozzle doesn't exist
            // e.g: - Shutdown-ed operation
            case .output(oid: let oid, let message):
                guard nozzles.has(oid) else { break }
                process.send(message.jsonString)

            // Kill actor
            case .acid:
                nozzles.values.forEach { $0.shutdown() }
                nozzles = [:]
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
    }
}
