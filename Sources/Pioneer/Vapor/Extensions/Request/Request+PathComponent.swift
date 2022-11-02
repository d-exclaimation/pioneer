//
//  Request+PathComponent.swift
//  pioneer
//
//  Created by d-exclaimation on 20:14.
//

import class Vapor.Request

extension Request {
    /// Path components from given URI path
    var pathComponents: [String] {
        guard let path = url.path.split(separator: "?", omittingEmptySubsequences: true).first else {
            return []
        }

        return String(path)
            .split(separator: "/", omittingEmptySubsequences: true)
            .map { String($0) }
            .compactMap { $0.removingPercentEncoding }
    }
}