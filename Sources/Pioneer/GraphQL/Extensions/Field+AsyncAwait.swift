//
//  Field+AsyncAwait.swift
//  Pioneer
//
//  Created by d-exclaimation on 4:38 PM.
//  Copyright © 2021 d-exclaimation. All rights reserved.
//

import Graphiti
import NIO

public extension Field where FieldType : Encodable {
    /// Async / Await Resolver for Graphiti
    typealias AsyncAwaitResolve<ObjectType, Context, Arguments, ResolveType> = (ObjectType) -> (Context, Arguments) async throws -> ResolveType

    convenience init(
        _ name: String,
        at function: @escaping AsyncAwaitResolve<ObjectType, Context, Arguments, FieldType>,
        @ArgumentComponentBuilder<Arguments> _ argument: () -> [ArgumentComponent<Arguments>]
    ) {
        let resolve: AsyncResolve<ObjectType, Context, Arguments, FieldType> = { type in
            { context, arguments, eventLoopGroup in
                eventLoopGroup.task { try await function(type)(context, arguments) }
            }
        }

        self.init(name, at: resolve, argument)
    }
}

extension EventLoopGroup {
    /// Async Closure
    typealias SendFunction<Value> = () async throws -> Value

    /// Create a promise that solve-able by an async function
    func task<Value>(_ body: @escaping SendFunction<Value>) -> EventLoopFuture<Value> {
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