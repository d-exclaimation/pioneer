//
//  SubscriptionField+AsyncAwait.swift
//  Pioneer
//
//  Created by d-exclaimation.
//

import Graphiti
import NIO
import GraphQL

/// Async-await non-throwing GraphQL subscription resolver function
public typealias AsyncAwaitSubscription<ObjectType, Context, Arguments, SourceEventType> = AsyncAwaitResolve<ObjectType, Context, Arguments, EventStream<SourceEventType>>

/// Async-await throwing GraphQL subscription resolver function
public typealias AsyncAwaitThrowingSubscription<ObjectType, Context, Arguments, SourceEventType> = AsyncAwaitThrowingResolve<ObjectType, Context, Arguments, EventStream<SourceEventType>>

public extension SubscriptionField {
    
    // -- (context, args) async -> subscriptions
    
    convenience init(
        _ name: String,
        as: FieldType.Type,
        atSub subFunc: @escaping AsyncAwaitSubscription<ObjectType, Context, Arguments, SourceEventType>,
        @ArgumentComponentBuilder<Arguments> _ argument: () -> [ArgumentComponent<Arguments>]
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

    
    // -- (context, args) async throws -> subscriptions

    convenience init(
        _ name: String,
        as: FieldType.Type,
        atSub subFunc: @escaping AsyncAwaitThrowingSubscription<ObjectType, Context, Arguments, SourceEventType>,
        @ArgumentComponentBuilder<Arguments> _ argument: () -> [ArgumentComponent<Arguments>]
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

