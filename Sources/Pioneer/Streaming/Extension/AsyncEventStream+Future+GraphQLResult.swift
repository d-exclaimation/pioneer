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
public typealias AsyncGraphQLSequence<Sequence: AsyncSequence> = AsyncEventStream<Future<GraphQLResult>, Sequence>
        where Sequence.Element == Future<GraphQLResult>


/// AsyncStream for GraphQL Result
public typealias AsyncGraphQLNozzle = AsyncGraphQLSequence<Nozzle<Future<GraphQLResult>>>

/// AsyncStream for GraphQL Result
public typealias GraphQLNozzle = EventNozzle<Future<GraphQLResult>>

/// AsyncStream for GraphQL Result
public typealias AsyncGraphQLStream = AsyncGraphQLSequence<AsyncStream<Future<GraphQLResult>>>

extension SubscriptionEventStream {
    /// Get the nozzle from this event stream regardless of its sequence
    public func nozzle() -> Nozzle<Future<GraphQLResult>>? {
        if let eventNozzle = self as? GraphQLNozzle {
            return eventNozzle.nozzle
        }
        if let asyncStream = self as? AsyncGraphQLStream {
            return asyncStream.nozzle
        }
        if let nozzle = self as? AsyncGraphQLNozzle {
            return nozzle.sequence
        }
        return nil
    }
}

extension AsyncEventStream where Element == Future<GraphQLResult> {
    /// Get the nozzle from this event stream regardless of its sequence
    public var nozzle: Nozzle<Future<GraphQLResult>> {
        let (nozzle, engine) = Nozzle<Future<GraphQLResult>>.desolate()
        Task.init {
            for try await each in sequence {
                await engine.task(with: .some(each))
            }
            await engine.task(with: nil)
        }
        return nozzle
    }
}

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