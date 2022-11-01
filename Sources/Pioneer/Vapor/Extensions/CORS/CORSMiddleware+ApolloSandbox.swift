//
//  CORSMiddleware+ApolloSandbox.swift
//  Pioneer
//
//  Created by d-exclaimation on 3:32 PM.
//

import struct NIOHTTP1.HTTPHeaders
import enum NIOHTTP1.HTTPMethod
import class Vapor.CORSMiddleware

extension CORSMiddleware.Configuration {
    /// Setup CORS for GraphQL allowing Apollo Sandbox
    ///
    /// - Parameters:
    ///   - urls: Extra allowed origins
    ///   - credentials: Allowing credentials through CORS
    ///   - headers: Allowed header names
    /// - Returns: CORS Configuration
    public static func apolloSandbox(
        origins urls: [String] = [],
        credentials: Bool = true,
        additionalHeaders headers: [HTTPHeaders.Name] = []
    ) -> CORSMiddleware.Configuration {
        let allowedOrigin: CORSMiddleware.AllowOriginSetting = .any(["https://studio.apollographql.com"] + urls)
        let allowedMethods: [HTTPMethod] = [.GET, .POST, .OPTIONS]
        let allowedHeaders: [HTTPHeaders.Name] = [
            .secWebSocketProtocol, .accept, .authorization, .contentType, .origin, .userAgent, .accessControlAllowOrigin, .xRequestedWith
        ] + headers
        
        return .init(
            allowedOrigin: allowedOrigin,
            allowedMethods: allowedMethods,
            allowedHeaders: allowedHeaders,
            allowCredentials: credentials
        )
    }
}
