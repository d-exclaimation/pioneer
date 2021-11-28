//
//  Field+AsyncAwait.swift
//  Pioneer
//
//  Created by d-exclaimation on 4:38 PM.
//  Copyright © 2021 d-exclaimation. All rights reserved.
//

import Graphiti
import NIO
import GraphQL

public extension Graphiti.Field where FieldType : Encodable {
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

    convenience init(
        _ name: String,
        at function: @escaping AsyncAwaitResolve<ObjectType, Context, Arguments, FieldType>
    ) where Arguments == NoArguments {
        let resolve: AsyncResolve<ObjectType, Context, Arguments, FieldType> = { type in
            { context, arguments, eventLoopGroup in
                eventLoopGroup.task { try await function(type)(context, arguments) }
            }
        }

        self.init(name, at: resolve, {})
    }
}

public extension SubscriptionField where FieldType : Encodable {
    /// Async / Await Subsbcription Resolver for Graphiti
    typealias AsyncAwaitSubscription<ObjectType, Context, Arguments, SourceEventType> = (ObjectType) -> (Context, Arguments) async throws -> EventStream<SourceEventType>

    convenience init(
        _ name: String,
        as: FieldType.Type,
        atSub subFunc: @escaping AsyncAwaitSubscription<ObjectType, Context, Arguments, SourceEventType>,
        @ArgumentComponentBuilder<Arguments> _ argument: () -> ArgumentComponent<Arguments>
    ) {
        let subscribe: AsyncResolve<ObjectType, Context, Arguments, EventStream<SourceEventType>> = { type in
            { context, arguments, eventLoopGroup in
                eventLoopGroup.task { try await subFunc(type)(context, arguments) }
            }
        }
        self.init(name, as: `as`, atSub: subscribe, argument)
    }

    convenience init(
        _ name: String,
        as: FieldType.Type,
        atSub subFunc: @escaping AsyncAwaitSubscription<ObjectType, Context, Arguments, SourceEventType>
    ) where Arguments == NoArguments {
        let subscribe: AsyncResolve<ObjectType, Context, Arguments, EventStream<SourceEventType>> = { type in
            { context, arguments, eventLoopGroup in
                eventLoopGroup.task { try await subFunc(type)(context, arguments) }
            }
        }
        self.init(name, as: `as`, atSub: subscribe)
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