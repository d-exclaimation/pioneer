//
//  Field+Middleware.swift
//  pioneer
//
//  Created by d-exclaimation on 00:13.
//

import class Graphiti.ArgumentComponent
import struct Graphiti.ArgumentComponentBuilder
import typealias Graphiti.ConcurrentResolve
import class Graphiti.Field
import typealias Graphiti.SyncResolve

public extension Field where FieldType: Encodable {
    convenience init(
        _ name: String,
        at function: @escaping SyncResolve<ObjectType, Context, Arguments, FieldType>,
        use middlewares: [GraphQLMiddleware<ObjectType, Context, Arguments, FieldType>],
        @ArgumentComponentBuilder<Arguments> _ argument: () -> ArgumentComponent<Arguments>
    ) {
        self.init(
            name: name,
            arguments: [argument()],
            concurrentResolve: buildResolver(from: function, using: middlewares)
        )
    }

    convenience init(
        _ name: String,
        at function: @escaping SyncResolve<ObjectType, Context, Arguments, FieldType>,
        use middlewares: [GraphQLMiddleware<ObjectType, Context, Arguments, FieldType>],
        @ArgumentComponentBuilder<Arguments> _ arguments: ()
            -> [ArgumentComponent<Arguments>] = { [] }
    ) {
        self.init(
            name: name,
            arguments: arguments(),
            concurrentResolve: buildResolver(from: function, using: middlewares)
        )
    }

    convenience init(
        _ name: String,
        at function: @escaping ConcurrentResolve<ObjectType, Context, Arguments, FieldType>,
        use middlewares: [GraphQLMiddleware<ObjectType, Context, Arguments, FieldType>],
        @ArgumentComponentBuilder<Arguments> _ argument: () -> ArgumentComponent<Arguments>
    ) {
        self.init(
            name: name,
            arguments: [argument()],
            concurrentResolve: buildResolver(from: function, using: middlewares)
        )
    }

    convenience init(
        _ name: String,
        at function: @escaping ConcurrentResolve<ObjectType, Context, Arguments, FieldType>,
        use middlewares: [GraphQLMiddleware<ObjectType, Context, Arguments, FieldType>],
        @ArgumentComponentBuilder<Arguments> _ arguments: ()
            -> [ArgumentComponent<Arguments>] = { [] }
    ) {
        self.init(
            name: name,
            arguments: arguments(),
            concurrentResolve: buildResolver(from: function, using: middlewares)
        )
    }
}
