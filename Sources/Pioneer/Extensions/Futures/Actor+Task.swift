//
//  Actor+Task.swift
//  Pioneer
//
//  Created by d-exclaimation on 11:41 PM.
//

public extension Actor {
    /// Method for handling NIO EventLoopFuture with an Actor using the pipe pattern
    ///
    /// - Parameters:
    ///   - future: EventLoopFuture value being awaited
    ///   - to: Transforming callback to for the result from the Future.
    func pipeToSelf<U>(future: Task<U, Error>, to callback: @Sendable @escaping (Self, Result<U, Error>) async -> Void) {
        Task {
            do {
                let res = try await future.value
                await callback(self, .success(res))
            } catch {
                await callback(self, .failure(error))
            }
        }
    }
}
