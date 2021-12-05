//
//  HttpStrategy.swift
//  Pioneer
//
//  Created by d-exclaimation on 4:30 PM.
//  Copyright © 2021 d-exclaimation. All rights reserved.
//

import Foundation

extension Pioneer {
    /// HTTP Operation and routing strategy for GraphQL
    public enum HTTPStrategy {
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
        /// Allow all operation through `GET` and `POST`.
        case both
    }
}