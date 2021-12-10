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
    /// - Parameter urls: Extra Allowed origins
    /// - Returns: CORS Configuration
    public static func graphqlWithBananaCakePop(with urls: [String] = []) -> CORSMiddleware.Configuration {
        let allowedOrigin: CORSMiddleware.AllowOriginSetting = .any(["https://eat.bananacakepop.com/"] + urls)
        let allowedMethods: [HTTPMethod] = [.GET, .POST, .OPTIONS]
        let allowedHeaders: [HTTPHeaders.Name] = [
            .secWebSocketProtocol, .accept, .authorization, .contentType, .origin, .userAgent, .accessControlAllowOrigin, .xRequestedWith
        ]
        return .init(allowedOrigin: allowedOrigin, allowedMethods: allowedMethods, allowedHeaders: allowedHeaders)
    }
}
