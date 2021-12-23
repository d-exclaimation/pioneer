//
//  Field+AsyncAwait.swift
//  Pioneer
//
//  Created by d-exclaimation on 4:38 PM.
//

import Graphiti
import NIO
import GraphQL

/// Async-await non-throwing GraphQL resolver function
public typealias AsyncAwaitResolve<ObjectType, Context, Arguments, FieldType> = (ObjectType) -> (Context, Arguments) async -> FieldType

/// Async-await throwing GraphQL resolver function
public typealias AsyncAwaitThrowingResolve<ObjectType, Context, Arguments, FieldType> = (ObjectType) -> (Context, Arguments) async throws -> FieldType

/// Async-await non-throwing  GraphQL resolver function
public typealias AsyncAwaitResolveWithEventLoop<ObjectType, Context, Arguments, FieldType> = (ObjectType) -> (Context, Arguments, EventLoopGroup) async -> FieldType

/// Async-await throwing  GraphQL resolver function
public typealias AsyncAwaitThrowingResolveWithEventLoop<ObjectType, Context, Arguments, FieldType> = (ObjectType) -> (Context, Arguments, EventLoopGroup) async throws -> FieldType

public extension Graphiti.Field where FieldType : Encodable {
    // -- (context, args) async -> result
    
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

    // -- (context, args) async throws -> result

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

    // -- (context, args, eventLoop) async -> result

    convenience init(
        _ name: String,
        at function: @escaping AsyncAwaitResolveWithEventLoop<ObjectType, Context, Arguments, FieldType>,
        @ArgumentComponentBuilder<Arguments> _ argument: () -> [ArgumentComponent<Arguments>]
    ) {
        let resolve: AsyncResolve<ObjectType, Context, Arguments, FieldType> = { type in
            { context, arguments, eventLoopGroup in
                eventLoopGroup.task {
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
                eventLoopGroup.task {
                    await function(type)(context, arguments, eventLoopGroup)
                }
            }
        }
        self.init(name, at: resolve, {})
    }

    // -- (context, args, eventLoop) async throws -> result

    convenience init(
        _ name: String,
        at function: @escaping AsyncAwaitThrowingResolveWithEventLoop<ObjectType, Context, Arguments, FieldType>,
        @ArgumentComponentBuilder<Arguments> _ argument: () -> [ArgumentComponent<Arguments>]
    ) {
        let resolve: AsyncResolve<ObjectType, Context, Arguments, FieldType> = { type in
            { context, arguments, eventLoopGroup in
                eventLoopGroup.task {
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
                eventLoopGroup.task {
                    try await function(type)(context, arguments, eventLoopGroup)
                }
            }
        }
        self.init(name, at: resolve, {})
    }

}


public extension Graphiti.Field {
    // -- (context, args) async -> result
    
    convenience init<ResolveType>(
        _ name: String,
        at function: @escaping AsyncAwaitResolve<ObjectType, Context, Arguments, ResolveType>,
        as: FieldType.Type,
        @ArgumentComponentBuilder<Arguments> _ argument: () -> [ArgumentComponent<Arguments>]
    ) {
        let resolve: AsyncResolve<ObjectType, Context, Arguments, ResolveType> = { type in
            { context, arguments, eventLoopGroup in
                eventLoopGroup.task { await function(type)(context, arguments) }
            }
        }

        self.init(name, at: resolve, as: `as`, argument)
    }

    convenience init<ResolveType>(
        _ name: String,
        at function: @escaping AsyncAwaitResolve<ObjectType, Context, Arguments, ResolveType>,
        as: FieldType.Type
    ) where Arguments == NoArguments {
        let resolve: AsyncResolve<ObjectType, Context, Arguments, ResolveType> = { type in
            { context, arguments, eventLoopGroup in
                eventLoopGroup.task { await function(type)(context, arguments) }
            }
        }
        
        self.init(name, at: resolve, as: `as`, {})
    }

    // -- (context, args) async throws -> result

    convenience init<ResolveType>(
        _ name: String,
        at function: @escaping AsyncAwaitThrowingResolve<ObjectType, Context, Arguments, ResolveType>,
        as: FieldType.Type,
        @ArgumentComponentBuilder<Arguments> _ argument: () -> [ArgumentComponent<Arguments>]
    ) {
        let resolve: AsyncResolve<ObjectType, Context, Arguments, ResolveType> = { type in
            { context, arguments, eventLoopGroup in
                eventLoopGroup.task { try await function(type)(context, arguments) }
            }
        }

        self.init(name, at: resolve, as: `as`, argument)
    }

    convenience init<ResolveType>(
        _ name: String,
        at function: @escaping AsyncAwaitThrowingResolve<ObjectType, Context, Arguments, ResolveType>,
        as: FieldType.Type
    ) where Arguments == NoArguments {
        let resolve: AsyncResolve<ObjectType, Context, Arguments, ResolveType> = { type in
            { context, arguments, eventLoopGroup in
                eventLoopGroup.task { try await function(type)(context, arguments) }
            }
        }

        self.init(name, at: resolve, as: `as`, {})
    }

    // -- (context, args, eventLoop) async -> result

    convenience init<ResolveType>(
        _ name: String,
        at function: @escaping AsyncAwaitResolveWithEventLoop<ObjectType, Context, Arguments, ResolveType>,
        as: FieldType.Type,
        @ArgumentComponentBuilder<Arguments> _ argument: () -> [ArgumentComponent<Arguments>]
    ) {
        let resolve: AsyncResolve<ObjectType, Context, Arguments, ResolveType> = { type in
            { context, arguments, eventLoopGroup in
                eventLoopGroup.task {
                    await function(type)(context, arguments, eventLoopGroup)
                }
            }
        }
        self.init(name, at: resolve, as: `as`, argument)
    }

    convenience init<ResolveType>(
        _ name: String,
        at function: @escaping AsyncAwaitResolveWithEventLoop<ObjectType, Context, Arguments, ResolveType>,
        as: FieldType.Type
    ) where Arguments == NoArguments {
        let resolve: AsyncResolve<ObjectType, Context, Arguments, ResolveType> = { type in
            { context, arguments, eventLoopGroup in
                eventLoopGroup.task {
                    await function(type)(context, arguments, eventLoopGroup)
                }
            }
        }
        self.init(name, at: resolve, as: `as`, {})
    }

    // -- (context, args, eventLoop) async throws -> result

    convenience init<ResolveType>(
        _ name: String,
        at function: @escaping AsyncAwaitThrowingResolveWithEventLoop<ObjectType, Context, Arguments, ResolveType>,
        as: FieldType.Type,
        @ArgumentComponentBuilder<Arguments> _ argument: () -> [ArgumentComponent<Arguments>]
    ) {
        let resolve: AsyncResolve<ObjectType, Context, Arguments, ResolveType> = { type in
            { context, arguments, eventLoopGroup in
                eventLoopGroup.task {
                    try await function(type)(context, arguments, eventLoopGroup)
                }
            }
        }
        self.init(name, at: resolve, as: `as`, argument)
    }
    
    convenience init<ResolveType>(
        _ name: String,
        at function: @escaping AsyncAwaitThrowingResolveWithEventLoop<ObjectType, Context, Arguments, ResolveType>,
        as: FieldType.Type
    ) where Arguments == NoArguments {
        let resolve: AsyncResolve<ObjectType, Context, Arguments, ResolveType> = { type in
            { context, arguments, eventLoopGroup in
                eventLoopGroup.task {
                    try await function(type)(context, arguments, eventLoopGroup)
                }
            }
        }
        self.init(name, at: resolve, as: `as`, {})
    }

}
