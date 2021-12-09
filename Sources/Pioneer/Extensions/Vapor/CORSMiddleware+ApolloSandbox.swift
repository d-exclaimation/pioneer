//
//  CORSMiddleware+ApolloSandbox.swift
//  pioneer-integration-test
//
//  Created by d-exclaimation on 3:32 PM.
//  Copyright © 2021 d-exclaimation. All rights reserved.
//

import Foundation
import NIOHTTP1
import Vapor

extension CORSMiddleware.Configuration {
    /// Setup CORS for GraphQL allowing Apollo Sandbox
    ///
    /// - Parameter urls: Extra Allowed origins
    /// - Returns: CORS Configuration
    public static func graphqlWithApolloSandbox(with urls: [String] = []) -> CORSMiddleware.Configuration {
        let allowedOrigin: CORSMiddleware.AllowOriginSetting = .any(["https://studio.apollographql.com"] + urls)
        let allowedMethods: [HTTPMethod] = [.GET, .POST, .OPTIONS]
        let allowedHeaders: [HTTPHeaders.Name] = [
            .secWebSocketProtocol, .accept, .authorization, .contentType, .origin, .userAgent, .accessControlAllowOrigin, .xRequestedWith
        ]
        return .init(allowedOrigin: allowedOrigin, allowedMethods: allowedMethods, allowedHeaders: allowedHeaders)
    }
}