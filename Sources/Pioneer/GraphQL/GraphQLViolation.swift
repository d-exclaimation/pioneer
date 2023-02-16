//
//  GraphQLViolation.swift
//  pioneer
//
//  Created by d-exclaimation on 20:04.
//

import enum NIOHTTP1.HTTPResponseStatus

/// Violation to the GraphQL over HTTP spec
public struct GraphQLViolation: Error, Sendable, Equatable {
    /// Different HTTP status codes for different media type as per GraphQL over HTTP spec
    public struct ResponseStatuses: Sendable, Equatable {
        /// Status for application/json
        public var json: HTTPResponseStatus
        /// Status for application/graphql-response+json
        public var graphql: HTTPResponseStatus

        public init(json: HTTPResponseStatus, graphql: HTTPResponseStatus) {
            self.json = json
            self.graphql = graphql
        }
    }

    /// Default message for this error
    public var message: String
    /// Appopriate HTTP status code for this error as per GraphQL over HTTP spec
    public var status: ResponseStatuses

    public init(message: String, status: HTTPResponseStatus) {
        self.message = message
        self.status = .init(json: status, graphql: status)
    }

    public init(message: String, status: ResponseStatuses) {
        self.message = message
        self.status = status
    }

    /// Get the appropriate HTTP status code for the media type
    /// - Parameter isAcceptingGraphQLResponse: If the accept media type is application/graphql-response+json
    /// - Returns: HTTP status code
    public func status(_ isAcceptingGraphQLResponse: Bool) -> HTTPResponseStatus {
        isAcceptingGraphQLResponse ? status.graphql : status.json
    }

    static var missingQuery: Self {
        .init(
            message: "Missing query in request",
            status: .init(json: .ok, graphql: .badRequest)
        )
    }

    static var invalidForm: Self {
        .init(
            message: "Invalid GraphQL request form",
            status: .init(json: .ok, graphql: .badRequest)
        )
    }

    static var invalidMethod: Self {
        .init(message: "Invalid HTTP method for a GraphQL request", status: .badRequest)
    }

    static var invalidContentType: Self {
        .init(message: "Invalid or missing content-type", status: .badRequest)
    }
}
