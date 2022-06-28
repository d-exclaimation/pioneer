//
//  EventLoopFuture+AsyncAwait.swift
//  Pioneer
//
//  Created by d-exclaimation.
//

import protocol NIO.EventLoopGroup
import class NIO.EventLoopFuture

extension EventLoopGroup {
    /// Create a promise that solve-able by an async function
    func task<Value>(_ body: @escaping () async throws -> Value) -> EventLoopFuture<Value> {
        let promise = next().makePromise(of: Value.self)
        Task.init {
            do {
                let value = try await body()
                promise.succeed(value)
            } catch {
                promise.fail(error)
            }
        }
        return promise.futureResult
    }
}
