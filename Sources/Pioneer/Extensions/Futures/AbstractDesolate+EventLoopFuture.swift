//
//  AbstractDesolate+EventLoopFuture.swift
//  Pioneer
//
//  Created by d-exclaimation on 11:41 PM.
//

import Foundation
import NIO

extension AbstractDesolate {
    /// Method for handling NIO EventLoopFuture with a Behavior `onMessage` using the pipe pattern
    ///
    /// - Parameters:
    ///   - future: EventLoopFuture value being awaited
    ///   - transform: Transforming callback to turn future value into a Behavior message.
    public func pipeToSelf<U>(future: EventLoopFuture<U>, to transform: @escaping (Result<U, Error>) -> MessageType) {
        let task = Task.init { () async throws -> U in
            try await future.get()
        }
        pipeToSelf(task, into: transform)
    }
}

extension AsyncSequence {
    /// Pipe back all this async sequence result into Actor as message to be handled concurrent safely
    ///
    /// - Parameters:
    ///   - ref: Desolated actor being sent messages to
    ///   - onComplete: Message given after completion
    ///   - onFailure: Message given if a failure occurred
    public func pipe<ActorType: AbstractDesolate>(
        to ref: Desolate<ActorType>,
        onComplete: @escaping () -> Self.Element,
        onFailure: @escaping (Error) -> Self.Element
    ) where Self.Element == ActorType.MessageType {
        Task.init {
            do {
                for try await elem in self {
                    await ref.task(with: elem)
                }
                await ref.task(with: onComplete())
            } catch {
                await ref.task(with: onFailure(error))
            }
        }
    }
}
