//
//  GraphQLMiddleware.swift
//  pioneer
//
//  Created by d-exclaimation on 17:38.
//

import typealias Graphiti.ConcurrentResolve
import typealias Graphiti.SyncResolve

/// A struct to group of all parameters for a resolvers
public struct ResolverParameters<Root, Context, Args> {
    /// The root element
    public var root: Root
    /// The context given for this operation
    public var context: Context
    /// The resolver arguments
    public var args: Args
}

/// Field resolver middleware specification
///
/// - Parameters:
///   - params: The resolver parameters
///   - next: The next function to be called
/// - Returns: The return type for the field resolver
public typealias GraphQLMiddleware<Root, Context, Args, ResolveType> = (
    _ params: ResolverParameters<Root, Context, Args>,
    _ next: @escaping () async throws -> ResolveType
) async throws -> ResolveType

/// Build a single resolver with a single base resolver and a handful middlewares
/// - Parameters:
///   - function: The base resolver 
///   - middlewares: The middlewares to wrap the resolvers
/// - Returns: A single resolver with middleware applied
public func buildResolver<Root, Context, Args, ResolveType>(
    from function: @escaping SyncResolve<Root, Context, Args, ResolveType>,
    using middlewares: [GraphQLMiddleware<Root, Context, Args, ResolveType>]
) -> ConcurrentResolve<Root, Context, Args, ResolveType> {
   { root in
        { ctx, args in
            let info = ResolverParameters(root: root, context: ctx, args: args)
            let result = middlewares
                .reversed()
                .reduce({ () async throws in try function(root)(ctx, args) }) { next, middleware in
                    { () async throws in
                        try await middleware(info, next)
                    }
                }
            return try await result()
        }
   }
}

/// Build a single resolver with a single base resolver and a handful middlewares
/// - Parameters:
///   - function: The base async resolver 
///   - middlewares: The middlewares to wrap the resolvers
/// - Returns: A single resolver with middleware applied
public func buildResolver<Root, Context, Args, ResolveType>(
    from function: @escaping ConcurrentResolve<Root, Context, Args, ResolveType>,
    using middlewares: [GraphQLMiddleware<Root, Context, Args, ResolveType>]
) -> ConcurrentResolve<Root, Context, Args, ResolveType> {
   { root in
        { ctx, args in
            let info = ResolverParameters(root: root, context: ctx, args: args)
            let result = middlewares
                .reversed()
                .reduce({ try await function(root)(ctx, args) }) { next, middleware in
                    { () async throws in
                        try await middleware(info, next)
                    }
                }
            return try await result()
        }
   }
}
