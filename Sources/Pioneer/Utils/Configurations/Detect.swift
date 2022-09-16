//
//  Detect.swift
//  Pioneer
//
//  Created by d-exclaimation on 20:17.
//

import class Vapor.Request
import class Vapor.Response
import struct Vapor.Environment
import class GraphQL.GraphQLSchema

public extension Pioneer.Config {
    /// Detect the configuration from the environment variables
    /// 
    /// Details on Environment variables used:
    /// - HTTPStrategy from `PIONEER_HTTP_STRATEGY` with values (`get`, `post`, `queryonlyget`, `mutationonlypost`, `split`, `csrf`, or `both`)
    /// - WebSocketProtocol from `PIONEER_WEBSOCKET_PROTOCOL` with values (`graphql-ws` or `subscriptions-transport-ws`)
    /// - Introspection from `PIONEER_INTROSPECTION` with any values meant true
    /// - GraphQL IDE from `PIONEER_PLAYGROUND` with values (`graphiql`, `apollo`, `sandbox`, or `bananacakepop`)
    /// - Keep alive interval from `PIONEER_KEEP_ALIVE` with any number in nanoseconds (leave empty to use default, otherwise interval is disabled)
    /// 
    /// - Parameters:
    ///   - schema: The GraphQL schema
    ///   - resolver: The top level object
    ///   - validationRules: Validation rules applied on every operations
    static func detect(
        using schema: GraphQLSchema, 
        resolver: Resolver,
        validationRules: Pioneer<Resolver, Context>.Validations = .none
    ) throws -> Self where Context == Void {
        try .detect(
            using: schema, 
            resolver: resolver, 
            context: { _, _ in }, 
            websocketContext: { _, _, _ in },
            validationRules: validationRules
        )
    }

    /// Detect the configuration from the environment variables
    /// 
    /// Details on Environment variables used:
    /// - HTTPStrategy from `PIONEER_HTTP_STRATEGY` with values (`get`, `post`, `queryonlyget`, `mutationonlypost`, `split`, `csrf`, or `both`)
    /// - WebSocketProtocol from `PIONEER_WEBSOCKET_PROTOCOL` with values (`graphql-ws` or `subscriptions-transport-ws`)
    /// - Introspection from `PIONEER_INTROSPECTION` with any values meant true
    /// - GraphQL IDE from `PIONEER_PLAYGROUND` with values (`graphiql`, `apollo`, `sandbox`, or `bananacakepop`)
    /// - Keep alive interval from `PIONEER_KEEP_ALIVE` with any number in nanoseconds (leave empty to use default, otherwise interval is disabled)
    /// 
    /// - Parameters:
    ///   - schema: The GraphQL schema
    ///   - resolver: The top level object
    ///   - context: The context builder for HTTP
    ///   - websocketContext: The context builder for WebSocket
    ///   - validationRules: Validation rules applied on every operations
    static func detect(
        using schema: GraphQLSchema, 
        resolver: Resolver, 
        context: @Sendable @escaping (Request, Response) async throws -> Context,
        websocketContext: @Sendable @escaping (Request, ConnectionParams, GraphQLRequest) async throws -> Context,
        validationRules: Pioneer<Resolver, Context>.Validations = .none
    ) throws -> Self {
        guard let strategy = Environment.get("PIONEER_HTTP_STRATEGY") else {
            throw Undetected.noHttpStrategy
        }
        guard let subprotocol = Environment.get("PIONEER_WEBSOCKET_PROTOCOL") else {
            throw Undetected.noWebsocketProtocol
        }
        let httpStrategy: Pioneer<Resolver, Context>.HTTPStrategy = try def {
            switch (strategy.lowercased().filter({ $0 == "-" || $0 == "_" }).description) {
            case "get", "onlyget":
                return .onlyGet
            case "post", "onlypost":
                return .onlyPost
            case "queryonlyget":
                return .queryOnlyGet
            case "mutationonlypost":
                return .mutationOnlyPost
            case "split", "splitqueryandmutation":
                return .splitQueryAndMutation
            case "csrf", "csrfprevention":
                return .csrfPrevention
            case "both", "all":
                return .both
            default:
                throw Undetected.noHttpStrategy
            }
        }

        let websocketProtocol: Pioneer<Resolver, Context>.WebsocketProtocol = try def {
            switch (subprotocol.lowercased()) {
                case "graphql-ws", "graphql_ws":
                    return .graphqlWs
                case "subscriptions-transport-ws", "subscriptions_transport_ws":
                    return .subscriptionsTransportWs
                default:
                    throw Undetected.noWebsocketProtocol
            }
        }

        let introspection = Environment.get("PIONEER_INTROSPECTION").isSome
        let playground: Pioneer<Resolver, Context>.IDE = def {
            switch (Environment.get("PIONEER_PLAYGROUND")?.lowercased()) {
            case .some("graphiql"):
                return .graphiql
            case .some("apollo"), .some("apollosandbox"):
                return .apolloSandbox
            case .some("sandbox"):
                return .sandbox
            case .some("bananacakepop"):
                return .redirect(to: .bananaCakePop)
            default:
                return .disable
            }
        }

        let keepAlive: UInt64? = UInt64(Environment.get("PIONEER_KEEP_ALIVE") ?? "12500000000")

        return .init(
            schema: schema, 
            resolver: resolver, 
            contextBuilder: context, 
            httpStrategy: httpStrategy, 
            websocketContextBuilder: websocketContext, 
            websocketProtocol: websocketProtocol, 
            introspection: introspection, 
            playground: playground, 
            validationRules: validationRules,
            keepAlive: keepAlive
        )
    }

    enum Undetected: Error {
        case noHttpStrategy
        case noWebsocketProtocol
    }
}