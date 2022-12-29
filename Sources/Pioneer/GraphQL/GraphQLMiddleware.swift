//
//  GraphQLMiddleware.swift
//  pioneer
//
//  Created by d-exclaimation on 17:38.
//

/// A struct to group of all parameters for a resolvers 
public struct ResolverParameters<ObjectType, Context, Arguments> {
    /// The root element
    public var root: ObjectType
    /// The context given for this operation
    public var context: Context
    /// The resolver arguments
    public var args: Arguments
} 

/// Field resolver middleware specification
/// 
/// - Parameters:
///   - params: The resolver parameters
///   - next: The next function to be called
/// - Returns: The return type for the field resolver
public typealias GraphQLMiddleware<ObjectType, Context, Arguments, FieldType> = (
    _ params: ResolverParameters<ObjectType, Context, Arguments>,
    _ next: @escaping () async throws -> FieldType
) async throws -> FieldType