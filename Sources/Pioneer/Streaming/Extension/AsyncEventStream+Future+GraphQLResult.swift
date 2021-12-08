//
//  AsyncEventStream+Future+GraphQLResult.swift
//  Pioneer
//
//  Created by d-exclaimation on 3:38 PM.
//  Copyright © 2021 d-exclaimation. All rights reserved.
//

import GraphQL
import Desolate

/// AsyncSequence for GraphQL Result
public typealias AsyncGraphQLSequence<Sequence: AsyncSequence> = AsyncEventStream<Future<GraphQL.GraphQLResult>, Sequence>
        where Sequence.Element == Future<GraphQL.GraphQLResult>

/// AsyncStream for GraphQL Result
public typealias AsyncGraphQLNozzle = AsyncGraphQLSequence<Nozzle<Future<GraphQL.GraphQLResult>>>

/// AsyncStream for GraphQL Result
public typealias AsyncGraphQLStream = AsyncGraphQLSequence<AsyncStream<Future<GraphQL.GraphQLResult>>>

extension SubscriptionEventStream {
    /// Get the AsyncStream from this event stream regardless of its sequence
    public func asyncStream() -> AsyncStream<Future<GraphQL.GraphQLResult>>? {
        switch self {
        case let asyncStream as AsyncGraphQLStream:
            return asyncStream.sequence
        case let nozzle as AsyncGraphQLNozzle:
            return nozzle.sequence.asyncStream()
        default:
            return nil
        }
    }
}

extension AsyncStream where Element == Future<GraphQL.GraphQLResult> {
    /// Pipe the GraphQLResult into a DesolatedActor.
    ///
    /// - Parameters:
    ///   - to: Desolate of an Actor.
    ///   - onComplete: A message for the actor on completion evaluated lazily.
    ///   - onFailure: A message for the actor given an error occurred.
    ///   - transform: A function to transform the GraphQLResult into a proper message
    /// - Returns:
    public func pipeBack<ActorType: AbstractDesolate>(
        to actorRef: Desolate<ActorType>,
        onComplete: @escaping () -> ActorType.MessageType,
        onFailure: @escaping (Error) -> ActorType.MessageType,
        transform: @escaping (GraphQL.GraphQLResult) -> ActorType.MessageType
    ) -> Deferred<Void> {
        Task.init {
            do {
                for await elem in self {
                    guard !Task.isCancelled else { return }
                    let fut: Future<GraphQL.GraphQLResult> = elem
                    let result = try await fut.get()
                    await actorRef.task(with: transform(result))
                }
                await actorRef.task(with: onComplete())
            } catch {
                await actorRef.task(with: onFailure(error))
            }
        }
    }
}