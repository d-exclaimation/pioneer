//
//  AsyncEventStream+Future+GraphQLResult.swift
//  GraphQLAsyncSequence
//
//  Created by d-exclaimation on 3:38 PM.
//  Copyright © 2021 d-exclaimation. All rights reserved.
//

import GraphQL
import Desolate

/// AsyncSequence for GraphQL Result
public typealias AsyncGraphQLSequence<Sequence: AsyncSequence> = AsyncEventStream<Future<GraphQLResult>, Sequence>
        where Sequence.Element == Future<GraphQLResult>


/// AsyncStream for GraphQL Result
public typealias AsyncGraphQLNozzle = AsyncGraphQLSequence<Nozzle<Future<GraphQLResult>>>

extension AsyncEventStream where Sequence == Nozzle<Future<GraphQLResult>> {
    /// Pipe the GraphQLResult into a DesolatedActor.
    ///
    /// - Parameters:
    ///   - actorRef: Desolate of an Actor.
    ///   - onComplete: A message for the actor on completion evaluated lazily.
    ///   - onFailure: A message for the actor given an error occurred.
    ///   - transform: A function to transform the GraphQLResult into a proper message
    /// - Returns:
    public func pipeTo<ActorType: AbstractDesolate>(
        actorRef: Desolate<ActorType>,
        onComplete: @escaping () -> ActorType.MessageType,
        onFailure: @escaping (Error) -> ActorType.MessageType,
        transform: @escaping (GraphQLResult) -> ActorType.MessageType
    ) -> Deferred<Void> {
        Task.init {
            do {
                for await elem in sequence {
                    let result = try await elem.get()
                    await actorRef.task(with: transform(result))
                }
                await actorRef.task(with: onComplete())
            } catch {
                await actorRef.task(with: onFailure(error))
            }
        }
    }
}