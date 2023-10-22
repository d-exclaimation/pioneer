//
//  AsyncEventStream+Future+GraphQLResult.swift
//  Pioneer
//
//  Created by d-exclaimation on 3:38 PM.
//

import NIOCore
import class GraphQL.ConcurrentEventStream
import class GraphQL.Future
import struct GraphQL.GraphQLResult
import class GraphQL.SubscriptionEventStream

/// AsyncSequence for GraphQL Result
public typealias AsyncGraphQLSequence<Sequence: AsyncSequence> = AsyncEventStream<Future<GraphQL.GraphQLResult>, Sequence>
    where Sequence.Element == Future<GraphQL.GraphQLResult>

/// AsyncStream for GraphQL Result
public typealias AsyncGraphQLStream = AsyncGraphQLSequence<AsyncThrowingStream<Future<GraphQL.GraphQLResult>, Error>>

public extension SubscriptionEventStream {
    /// Get the AsyncStream from this event stream regardless of its sequence
    func asyncStream() -> AsyncThrowingStream<Future<GraphQL.GraphQLResult>, Error>? {
        if let asyncStream = self as? AsyncGraphQLStream {
            return asyncStream.sequence
        }
        if let concurrentStream = self as? ConcurrentEventStream<Future<GraphQL.GraphQLResult>> {
            return concurrentStream.stream
        }
        return nil
    }
}

public extension AsyncSequence where Element == Future<GraphQL.GraphQLResult> {
    /// Pipe the GraphQLResult AsyncSequence into an actor.
    ///
    /// - Parameters:
    ///   - to: Any type of Actor.
    ///   - complete: A callback ran when this sequence completes.
    ///   - error: A callback ran when an error were thrown when reading elements from this sequence.
    ///   - next: A callback ran on each element of this sequence.
    /// - Returns: The Task used to consume this AsyncSequence
    func pipe<ActorType: Actor>(
        to sink: ActorType,
        complete: @Sendable @escaping (ActorType) async -> Void,
        failure: @Sendable @escaping (ActorType, Error) async -> Void,
        next: @Sendable @escaping (ActorType, GraphQL.GraphQLResult) async -> Void
    ) -> Task<Void, Error> {
        Task.init {
            do {
                for try await elem in self {
                    guard !Task.isCancelled else { return }
                    let fut: Future<GraphQL.GraphQLResult> = elem
                    let result = try await fut.get()
                    await next(sink, result)
                }
                await complete(sink)
            } catch {
                await failure(sink, error)
            }
        }
    }
}
