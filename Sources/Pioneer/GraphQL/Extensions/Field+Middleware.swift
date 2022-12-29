//
//  Field+Middleware.swift
//  pioneer
//
//  Created by d-exclaimation on 00:13.
//

import class Graphiti.Field
import class Graphiti.ArgumentComponent
import struct Graphiti.ArgumentComponentBuilder
import typealias Graphiti.ConcurrentResolve
import typealias Graphiti.SyncResolve

public extension Field where FieldType: Encodable {
    convenience init(
        _ name: String,
        at function: @escaping SyncResolve<ObjectType, Context, Arguments, FieldType>,
        use middlewares: [GraphQLMiddleware<ObjectType, Context, Arguments, FieldType>],
        @ArgumentComponentBuilder<Arguments> _ argument: () -> ArgumentComponent<Arguments>
    ) {
        let resolve: ConcurrentResolve<ObjectType, Context, Arguments, FieldType> = { type in
            { context, arguments in
                let info = ResolverParameters(root: type, context: context, args: arguments)
                let result = middlewares
                    .reversed()
                    .reduce({ () async throws -> FieldType in 
                        try function(type)(context, arguments) 
                    }) { acc, middleware in
                        return { () async throws -> FieldType in
                            try await middleware(info, acc)
                        }
                    }
                return try await result()
            }
        }
        self.init(name: name, arguments: [argument()], concurrentResolve: resolve)
    }

    convenience init(
        _ name: String,
        at function: @escaping SyncResolve<ObjectType, Context, Arguments, FieldType>,
        use middlewares: [GraphQLMiddleware<ObjectType, Context, Arguments, FieldType>],
        @ArgumentComponentBuilder<Arguments> _ arguments: ()
            -> [ArgumentComponent<Arguments>] = { [] }
    ) {
        let resolve: ConcurrentResolve<ObjectType, Context, Arguments, FieldType> = { type in
            { context, arguments in
                let info = ResolverParameters(root: type, context: context, args: arguments)
                let result = middlewares
                    .reversed()
                    .reduce({ () async throws -> FieldType in
                        try function(type)(context, arguments)
                    }) { acc, middleware in
                        return { () async throws -> FieldType in
                            try await middleware(info, acc)
                        }
                    }
                return try await result()
            }
        }
        self.init(name: name, arguments: arguments(), concurrentResolve: resolve)
    }

    convenience init(
        _ name: String,
        at function: @escaping ConcurrentResolve<ObjectType, Context, Arguments, FieldType>,
        use middlewares: [GraphQLMiddleware<ObjectType, Context, Arguments, FieldType>],
        @ArgumentComponentBuilder<Arguments> _ argument: () -> ArgumentComponent<Arguments>
    ) {
        let resolve: ConcurrentResolve<ObjectType, Context, Arguments, FieldType> = { type in
            { context, arguments in
                let info = ResolverParameters(root: type, context: context, args: arguments)
                let result = middlewares
                    .reversed()
                    .reduce({ try await function(type)(context, arguments) }) { acc, middleware in
                        return { () async throws -> FieldType in
                            try await middleware(info, acc)
                        }
                    }
                return try await result()
            }
        }
        self.init(name: name, arguments: [argument()], concurrentResolve: resolve)
    }

    convenience init(
        _ name: String,
        at function: @escaping ConcurrentResolve<ObjectType, Context, Arguments, FieldType>,
        use middlewares: [GraphQLMiddleware<ObjectType, Context, Arguments, FieldType>],
        @ArgumentComponentBuilder<Arguments> _ arguments: ()
            -> [ArgumentComponent<Arguments>] = { [] }
    ) {
        let resolve: ConcurrentResolve<ObjectType, Context, Arguments, FieldType> = { type in
            { context, arguments in
                let info = ResolverParameters(root: type, context: context, args: arguments)
                let result = middlewares
                    .reversed()
                    .reduce({ try await function(type)(context, arguments) }) { acc, middleware in
                        return { () async throws -> FieldType in
                            try await middleware(info, acc)
                        }
                    }
                return try await result()
            }
        }
        self.init(name: name, arguments: arguments(), concurrentResolve: resolve)
    }
}