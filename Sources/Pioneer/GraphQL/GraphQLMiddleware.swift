//
//  GraphQLMiddleware.swift
//  pioneer
//
//  Created by d-exclaimation on 17:38.
//

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
