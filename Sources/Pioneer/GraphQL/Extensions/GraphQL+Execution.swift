//
//  GraphQL+Execution.swift
//  Pioneer
//
//  Created by d-exclaimation on 9:46 PM.
//  Copyright © 2021 d-exclaimation. All rights reserved.
//


import GraphQL
import NIO


/// Execute request-response based GraphQL Operation
/// 
/// - Parameters:
///   - schema: GraphQL Schema used to execute request
///   - request: Query request string
///   - resolver: Resolver used to resolve execution
///   - context: Context value passed in
///   - eventLoopGroup: EventLoopGroup used to run execution asynchronously
///   - variables: Variables given from the request
///   - operationName: Operation name being executed
/// - Throws: Failure in dispatching actions
/// - Returns: A GraphQL Result
public func executeGraphQL(
    schema: GraphQLSchema,
    request: String,
    resolver: Any,
    context: Any,
    eventLoopGroup: EventLoopGroup,
    variables: [String: Map]? = nil,
    operationName: String? = nil
) async throws -> GraphQLResult {
    try await graphql(
        schema: schema,
        request: request,
        rootValue: resolver,
        context: context,
        eventLoopGroup: eventLoopGroup,
        variableValues: variables ?? [:],
        operationName: operationName
    ).get()
}


/// Execute streaming based GraphQL Operation
///
/// - Parameters:
///   - schema: GraphQL Schema used to execute request
///   - request: Query request string
///   - resolver: Resolver used to resolve execution
///   - context: Context value passed in
///   - eventLoopGroup: EventLoopGroup used to run execution asynchronously
///   - variables: Variables given from the request
///   - operationName: Operation name being executed
/// - Throws: Failure in dispatching actions
/// - Returns: A GraphQL Subscriptions Result Result
public func subscribeGraphQL(
    schema: GraphQLSchema,
    request: String,
    resolver: Any,
    context: Any,
    eventLoopGroup: EventLoopGroup,
    variables: [String: Map]? = nil,
    operationName: String? = nil
) async throws -> SubscriptionResult {
    try await graphqlSubscribe(
        schema: schema,
        request: request,
        rootValue: resolver,
        context: context,
        eventLoopGroup: eventLoopGroup,
        variableValues: variables ?? [:],
        operationName: operationName
    ).get()
}
