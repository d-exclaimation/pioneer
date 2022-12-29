//
//  HttpStrategy.swift
//  Pioneer
//
//  Created by d-exclaimation on 4:30 PM.
//

import enum GraphQL.OperationType
import enum NIOHTTP1.HTTPMethod

public extension Pioneer {
    /// HTTP Operation and routing strategy for GraphQL
    enum HTTPStrategy {
        /// Only allow `POST` GraphQL Request, most common choice
        case onlyPost
        /// Only allow `GET` GraphQL Request, not recommended for most
        case onlyGet
        /// Allow all operation through `POST` and allow only Queries through `GET`, recommended to utilize CORS
        case queryOnlyGet
        /// Allow all operation through `GET` and allow only Mutations through `POST`, utilize browser GET cache but not recommended
        case mutationOnlyPost
        /// Query must go through `GET` while any mutations through `POST`, follow and utilize HTTP conventions
        case splitQueryAndMutation
        /// Allow all operation through `POST`, allow only Queries through `GET`, and enable Apollo's CSRF and XS-Search prevention
        case csrfPrevention
        /// Allow all operation through `GET` and `POST`.
        case both

        /// Get the allowed operation for aa type of HTTPMethod
        /// - Parameter method: The HTTP Method this operation is executed
        /// - Returns: A list of allowed GraphQL Operation Type
        public func allowed(for method: HTTPMethod) -> [OperationType] {
            switch (method, self) {
            case (.GET, .onlyPost):
                return []
            case (.POST, .onlyPost):
                return [.query, .mutation]
            case (.GET, .onlyGet):
                return [.query, .mutation]
            case (.POST, .onlyGet):
                return []
            case (.GET, .queryOnlyGet), (.GET, .csrfPrevention):
                return [.query]
            case (.POST, .queryOnlyGet), (.POST, .csrfPrevention):
                return [.query, .mutation]
            case (.GET, .mutationOnlyPost):
                return [.query, .mutation]
            case (.POST, .mutationOnlyPost):
                return [.mutation]
            case (.GET, .splitQueryAndMutation):
                return [.query]
            case (.POST, .splitQueryAndMutation):
                return [.mutation]
            case (_, .both):
                return [.query, .mutation]
            default:
                return []
            }
        }
    }
}
