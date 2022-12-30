//
//  Expression.swift
//  Pioneer
//
//  Created by d-exclaimation.
//

/// Define an expression from a closure
/// - Returns: The returned value of this closure
public func expression<ReturnType>(_ fn: () throws -> ReturnType) rethrows -> ReturnType {
    try fn()
}

/// Define an expression from a closure
/// - Returns: The returned value of this closure
public func expression<ReturnType>(_ fn: () async throws -> ReturnType) async rethrows -> ReturnType {
    try await fn()
}
