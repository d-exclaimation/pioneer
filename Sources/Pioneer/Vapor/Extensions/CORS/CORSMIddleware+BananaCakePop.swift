//
//  CORSMiddleware+BananaCakePop.swift
//  Pioneer
//
//  Created by d-exclaimation.
//

import struct NIOHTTP1.HTTPHeaders
import enum NIOHTTP1.HTTPMethod
import class Vapor.CORSMiddleware

public extension CORSMiddleware.Configuration {
    /// Setup CORS for GraphQL allowing Banana Cake Pop GraphQL IDE (Cloud Version)
    ///
    /// - Parameters:
    ///   - urls: Extra allowed origins
    ///   - credentials: Allowing credentials through CORS
    ///   - headers: Allowed header names
    /// - Returns: CORS Configuration
    static func bananaCakePop(
        origins urls: [String] = [],
        credentials: Bool = false,
        additionalHeaders headers: [HTTPHeaders.Name] = []
    ) -> CORSMiddleware.Configuration {
        let allowedOrigin: CORSMiddleware.AllowOriginSetting = .any(["https://eat.bananacakepop.com/"] + urls)
        let allowedMethods: [HTTPMethod] = [.GET, .POST, .OPTIONS]
        let allowedHeaders: [HTTPHeaders.Name] = [
            .secWebSocketProtocol, .accept, .authorization, .contentType, .origin, .userAgent, .accessControlAllowOrigin, .xRequestedWith,
        ] + headers

        return .init(
            allowedOrigin: allowedOrigin,
            allowedMethods: allowedMethods,
            allowedHeaders: allowedHeaders,
            allowCredentials: credentials
        )
    }
}
