//
//  Drone.swift
//  Pioneer
//
//  Created by d-exclaimation on 4:55 PM.
//

import GraphQL
import class Graphiti.Schema
import class Vapor.Request
import protocol NIO.EventLoopGroup

extension Pioneer {
    /// Drone acting as concurrent safe actor for each client managing operations and subscriptions
    actor Drone {
        private let client: WebSocketClient
        private let schema: GraphQLSchema
        private let resolver: Resolver
        private let proto: SubProtocol.Type

        init(
            _ client: WebSocketClient, 
            schema: GraphQLSchema, 
            resolver: Resolver, 
            proto: SubProtocol.Type
        ) {
            self.schema = schema
            self.resolver = resolver
            self.proto = proto
            self.client = client
        }

        init(
            _ client: WebSocketClient, 
            schema: Schema<Resolver, Context>, 
            resolver: Resolver, 
            proto: SubProtocol.Type
        ) {
            self.schema = schema.schema
            self.resolver = resolver
            self.proto = proto
            self.client = client
        }

        // MARK: - Private mutable states
        private var tasks: [String: Task<Void, Error>] = [:]
        
        // MARK: - Event callbacks
        
        /// Start subscriptions, setup pipe pattern, and callbacks
        func start(for oid: String, given gql: GraphQLRequest) async {
            let nextTypename = proto.next
            let subscriptionResult = await subscription(gql: gql)
            
            // Guard for getting the required subscriptions stream, if not send `next` with errors, and end subscription
            guard let subscription = subscriptionResult.stream else {
                let res = GraphQL.GraphQLResult(errors: subscriptionResult.errors)
                client.out(GraphQLMessage.from(type: proto.next, id: oid, res).jsonString)
                client.out(GraphQLMessage(id: oid, type: proto.complete).jsonString)
                return
            }
            
            // Guard for getting the async stream, if not sent `next` saying failure in convertion, and end subscription
            guard let asyncStream = subscription.asyncStream() else {
                let res = GraphQL.GraphQLResult(errors: [
                    .init(message: "Internal server error, failed to fetch AsyncThrowingStream")
                ])
                client.out(GraphQLMessage.from(type: proto.next, id: oid, res).jsonString)
                client.out(GraphQLMessage(id: oid, type: proto.complete).jsonString)
                return
            }


            // Transform async stream into messages and pipe back all messages into the Actor itself
            let task = asyncStream.pipe(
                to: self,
                complete: { sink in
                    await sink.end(for: oid)
                },
                failure: { sink, error in
                    await sink.next(for: oid, given: .from(type: nextTypename, id: oid, .init(errors: [error.graphql])))
                    await sink.end(for: oid)
                },
                next: { sink, res in
                    await sink.next(for: oid, given: .from(type: nextTypename, id: oid, res))
                }
            )
            tasks.update(oid, with: task)
        }
        
        /// Stop subscription, shutdown task and remove it so preventing overflow of any messages
        func stop(for oid: String) {
            guard let task = tasks[oid] else { return }

            tasks.delete(oid)
            task.cancel()
        }
        
        /// Send an ending message
        /// but prevent completion message if task doesn't exist
        /// e.g: - Shutdown-ed operation
        func end(for oid: String) {
            guard tasks.has(oid) else { return }
            tasks.delete(oid)
            let message = GraphQLMessage(id: oid, type: proto.complete)
            client.out(message.jsonString)
        }
        
        /// Push message to websocket connection
        /// but prevent completion message if task doesn't exist
        /// e.g: - Shutdown-ed operation
        func next(for oid: String, given msg: GraphQLMessage) {
            guard tasks.has(oid) else { return }
            client.out(msg.jsonString)
        }
        
        /// Kill actor by cancelling and deallocating all stored task
        func acid() {
            tasks.values.forEach { $0.cancel() }
            tasks.removeAll()
        }
        
        // MARK: - Utility methods

        /// Build context and execute subscription from GraphQL Resolver and Schema, await the future value and catch error into a SubscriptionResult
        private func subscription(gql: GraphQLRequest) async -> SubscriptionResult {
            do {
                let ctx = try await client.context(gql)
                return try await subscribeOperation(for: gql, with: ctx, using: client.ev)
            } catch {
                return .init(
                    stream: nil,
                    errors: [.init(error)]
                )
            }
        }

        /// Execute long lived GraphQL Operation as a subscription
        private func subscribeOperation(for gql: GraphQLRequest, with ctx: Context, using eventLoop: EventLoopGroup) async throws -> SubscriptionResult {
            try await subscribeGraphQL(
                schema: schema, 
                request: gql.query,
                resolver: resolver, 
                context: ctx, 
                eventLoopGroup: eventLoop,
                variables: gql.variables,
                operationName: gql.operationName
            )
        }
    }
}
