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

    /// Async-await non-throwing GraphQL resolver function
    typealias AsyncAwaitResolve<ObjectType, Context, Arguments, FieldType> = (ObjectType) -> (Context, Arguments) async -> FieldType

    convenience init(
        _ name: String,
        at function: @escaping AsyncAwaitResolve<ObjectType, Context, Arguments, FieldType>,
        @ArgumentComponentBuilder<Arguments> _ argument: () -> [ArgumentComponent<Arguments>]
    ) {
        let resolve: AsyncResolve<ObjectType, Context, Arguments, FieldType> = { type in
            { context, arguments, eventLoopGroup in
                eventLoopGroup.task { await function(type)(context, arguments) }
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
                eventLoopGroup.task { await function(type)(context, arguments) }
            }
        }

        self.init(name, at: resolve, {})
    }


    /// Async-await throwing GraphQL resolver function
    typealias AsyncAwaitThrowingResolve<ObjectType, Context, Arguments, FieldType> = (ObjectType) -> (Context, Arguments) async throws -> FieldType

    convenience init(
        _ name: String,
        at function: @escaping AsyncAwaitThrowingResolve<ObjectType, Context, Arguments, FieldType>,
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
        at function: @escaping AsyncAwaitThrowingResolve<ObjectType, Context, Arguments, FieldType>
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
    /// Async-await throwing GraphQL subscription resolver function
    typealias AsyncAwaitSubscription<ObjectType, Context, Arguments, SourceEventType> = (ObjectType) -> (Context, Arguments) async -> EventStream<SourceEventType>

    convenience init(
        _ name: String,
        as: FieldType.Type,
        atSub subFunc: @escaping AsyncAwaitSubscription<ObjectType, Context, Arguments, SourceEventType>,
        @ArgumentComponentBuilder<Arguments> _ argument: () -> ArgumentComponent<Arguments>
    ) {
        let subscribe: AsyncResolve<ObjectType, Context, Arguments, EventStream<SourceEventType>> = { type in
            { context, arguments, eventLoopGroup in
                eventLoopGroup.task { await subFunc(type)(context, arguments) }
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
                eventLoopGroup.task { await subFunc(type)(context, arguments) }
            }
        }
        self.init(name, as: `as`, atSub: subscribe)
    }

    /// Async-await throwing GraphQL subscription resolver function
    typealias AsyncAwaitThrowingSubscription<ObjectType, Context, Arguments, SourceEventType> = (ObjectType) -> (Context, Arguments) async throws -> EventStream<SourceEventType>

    convenience init(
        _ name: String,
        as: FieldType.Type,
        atSub subFunc: @escaping AsyncAwaitThrowingSubscription<ObjectType, Context, Arguments, SourceEventType>,
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
        atSub subFunc: @escaping AsyncAwaitThrowingSubscription<ObjectType, Context, Arguments, SourceEventType>
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