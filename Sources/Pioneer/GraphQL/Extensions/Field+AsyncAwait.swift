//
//  Field+AsyncAwait.swift
//  Pioneer
//
//  Created by d-exclaimation on 4:38 PM.
//

import Graphiti
import GraphQL
import protocol NIO.EventLoopGroup

/// Async-await non-throwing  GraphQL resolver function
public typealias AsyncAwaitResolveWithEventLoop<ObjectType, Context, Arguments, FieldType> = (ObjectType) -> (Context, Arguments, EventLoopGroup) async -> FieldType

/// Async-await throwing  GraphQL resolver function
public typealias AsyncAwaitThrowingResolveWithEventLoop<ObjectType, Context, Arguments, FieldType> = (ObjectType) -> (Context, Arguments, EventLoopGroup) async throws -> FieldType

public extension Graphiti.Field where FieldType: Encodable {
    // -- (context, args, eventLoop) async -> result

    convenience init(
        _ name: String,
        at function: @escaping AsyncAwaitResolveWithEventLoop<ObjectType, Context, Arguments, FieldType>,
        @ArgumentComponentBuilder<Arguments> _ argument: () -> [ArgumentComponent<Arguments>]
    ) {
        let resolve: AsyncResolve<ObjectType, Context, Arguments, FieldType> = { type in
            { context, arguments, eventLoopGroup in
                eventLoopGroup.makeFutureWithTask {
                    await function(type)(context, arguments, eventLoopGroup)
                }
            }
        }
        self.init(name, at: resolve, argument)
    }

    convenience init(
        _ name: String,
        at function: @escaping AsyncAwaitResolveWithEventLoop<ObjectType, Context, Arguments, FieldType>
    ) where Arguments == NoArguments {
        let resolve: AsyncResolve<ObjectType, Context, Arguments, FieldType> = { type in
            { context, arguments, eventLoopGroup in
                eventLoopGroup.makeFutureWithTask {
                    await function(type)(context, arguments, eventLoopGroup)
                }
            }
        }
        self.init(name, at: resolve) {}
    }

    // -- (context, args, eventLoop) async throws -> result

    convenience init(
        _ name: String,
        at function: @escaping AsyncAwaitThrowingResolveWithEventLoop<ObjectType, Context, Arguments, FieldType>,
        @ArgumentComponentBuilder<Arguments> _ argument: () -> [ArgumentComponent<Arguments>]
    ) {
        let resolve: AsyncResolve<ObjectType, Context, Arguments, FieldType> = { type in
            { context, arguments, eventLoopGroup in
                eventLoopGroup.makeFutureWithTask {
                    try await function(type)(context, arguments, eventLoopGroup)
                }
            }
        }
        self.init(name, at: resolve, argument)
    }

    convenience init(
        _ name: String,
        at function: @escaping AsyncAwaitThrowingResolveWithEventLoop<ObjectType, Context, Arguments, FieldType>
    ) where Arguments == NoArguments {
        let resolve: AsyncResolve<ObjectType, Context, Arguments, FieldType> = { type in
            { context, arguments, eventLoopGroup in
                eventLoopGroup.makeFutureWithTask {
                    try await function(type)(context, arguments, eventLoopGroup)
                }
            }
        }
        self.init(name, at: resolve) {}
    }
}