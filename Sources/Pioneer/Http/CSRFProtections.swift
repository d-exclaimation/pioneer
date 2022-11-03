//
//  CSRFProtections.swift
//  pioneer
//
//  Created by d-exclaimation on 13:02.
//

import struct NIOHTTP1.HTTPHeaders

public extension Pioneer {
    /// Check the headers show signs of CSRF vunerabilities
    /// - Parameter headers: HTTP Headers by NIO standard
    /// - Returns: True if vulnerable
    func csrfVunerable(given headers: HTTPHeaders) -> Bool {
        // If CSRF Prevention is disabled, it is deemed not vunelrable
        guard case .csrfPrevention = httpStrategy else {
            return false
        }

        let hasPreflight = !headers[HTTPHeaders.Name("Apollo-Require-Preflight")].isEmpty
        let hasOperationName = !headers[HTTPHeaders.Name("X-Apollo-Operation-Name")].isEmpty
        if hasPreflight || hasOperationName {
            return false
        }
        let restrictedHeaders = ["text/plain", "application/x-www-form-urlencoded", "multipart/form-data"]
        let contentTypes = headers[.contentType]
        return contentTypes.contains { contentType in
            restrictedHeaders.contains {
                contentType.lowercased().contains($0)
            }
        }
    }
}
