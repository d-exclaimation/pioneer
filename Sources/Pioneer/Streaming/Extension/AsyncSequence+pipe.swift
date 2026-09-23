//
//  AsyncSequence+pipe.swift
//  Pioneer
//
//  Created by d-exclaimation on 3:38 PM.
//

import NIOCore
import struct GraphQL.GraphQLResult

public extension AsyncSequence where Element == GraphQL.GraphQLResult {
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
                for try await result in self {
                    guard !Task.isCancelled else { return }
                    await next(sink, result)
                }
                await complete(sink)
            } catch {
                await failure(sink, error)
            }
        }
    }
}
