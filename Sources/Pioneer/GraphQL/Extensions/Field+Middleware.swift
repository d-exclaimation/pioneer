//
//  Field+Middleware.swift
//  pioneer
//
//  Created by d-exclaimation on 00:13.
//

import class Graphiti.ArgumentComponent
import struct Graphiti.ArgumentComponentBuilder
import typealias Graphiti.AsyncResolve
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
            name,
            at: buildResolver(from: function, using: middlewares),
            argument
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
            name,
            at: buildResolver(from: function, using: middlewares),
            arguments
        )
    }

    convenience init(
        _ name: String,
        at function: @escaping AsyncResolve<ObjectType, Context, Arguments, FieldType>,
        use middlewares: [GraphQLMiddleware<ObjectType, Context, Arguments, FieldType>],
        @ArgumentComponentBuilder<Arguments> _ argument: () -> ArgumentComponent<Arguments>
    ) {
        self.init(
            name,
            at: buildResolver(from: function, using: middlewares),
            argument
        )
    }

    convenience init(
        _ name: String,
        at function: @escaping AsyncResolve<ObjectType, Context, Arguments, FieldType>,
        use middlewares: [GraphQLMiddleware<ObjectType, Context, Arguments, FieldType>],
        @ArgumentComponentBuilder<Arguments> _ arguments: ()
            -> [ArgumentComponent<Arguments>] = { [] }
    ) {
        self.init(
            name,
            at: buildResolver(from: function, using: middlewares),
            arguments
        )
    }
}
