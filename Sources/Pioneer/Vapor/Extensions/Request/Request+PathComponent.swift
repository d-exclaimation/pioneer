//
//  Request+PathComponent.swift
//  pioneer
//
//  Created by d-exclaimation on 20:14.
//

import class Vapor.Request
import enum Vapor.PathComponent

extension Request {
    /// Path components from given URI path
    public var pathComponents: [String] {
        guard let path = url.path.split(separator: "?", omittingEmptySubsequences: true).first else {
            return []
        }

        return String(path)
            .split(separator: "/", omittingEmptySubsequences: true)
            .map { String($0) }
            .compactMap { $0.removingPercentEncoding }
    }

    /// Match the request url and the path components
    /// - Parameter path: The path components to be match against
    /// - Returns: True if url matches the path components
    public func matching(path: [PathComponent]) -> Bool {
        let components = pathComponents
        
        // Empty path, only matches empty url
        guard !path.isEmpty else {
            return components.isEmpty
        }

        // Zipped the path and url together, fill the missing ones with an empty ""
        let zipped = path
            .enumerated()
            .map { (i, each) -> (String?, PathComponent) in 
                i < components.count ? (components[i], each) : (nil, each)
            }

        for (component, pattern) in zipped {
            switch (pattern) {
                case .catchall:
                    return true
                case .anything, .constant(component):
                    continue
                default:
                    return false
            }
        }
        return components.count == path.count
    }
}