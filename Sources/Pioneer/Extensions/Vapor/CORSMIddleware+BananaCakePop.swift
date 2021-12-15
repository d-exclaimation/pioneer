//
//  CORSMiddleware+BananaCakePop.swift
//  Pioneer
//
//  Created by d-exclaimation.
//

import Vapor
import NIOHTTP1

extension CORSMiddleware.Configuration {
    /// Setup CORS for GraphQL allowing Banana Cake Pop GraphQL IDE (Cloud Version)
    ///
    /// - Parameters:
    ///   - urls: Extra allowed origins
    ///   - credentials: Allowing credentials through CORS
    ///   - headers: Allowed header names
    /// - Returns: CORS Configuration
    public static func graphqlWithBananaCakePop(
        origins urls: [String] = [],
        credentials: Bool = false,
        additionalHeaders headers: [HTTPHeaders.Name] = []
    ) -> CORSMiddleware.Configuration {
        let allowedOrigin: CORSMiddleware.AllowOriginSetting = .any(["https://eat.bananacakepop.com/"] + urls)
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
