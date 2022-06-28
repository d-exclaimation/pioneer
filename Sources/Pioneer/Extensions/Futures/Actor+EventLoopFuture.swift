//
//  Actor+EventLoopFuture.swift
//  Pioneer
//
//  Created by d-exclaimation on 11:41 PM.
//

import class NIO.EventLoopFuture

extension Actor {
    /// Method for handling NIO EventLoopFuture with an Actor using the pipe pattern
    ///
    /// - Parameters:
    ///   - future: EventLoopFuture value being awaited
    ///   - to: Transforming callback to for the result from the Future.
    public func pipeToSelf<U>(future: EventLoopFuture<U>, to callback: @escaping @Sendable (Self, Result<U, Error>) async -> Void) {
        Task {
            do {
                let res = try await future.get()
                await callback(self, .success(res))
            } catch {
                await callback(self, .failure(error))
            }
        }
    }
}
