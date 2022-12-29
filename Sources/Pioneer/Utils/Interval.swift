//
//  Interval.swift
//  pioneer
//
//  Created by d-exclaimation on 10:22.
//

/// Create an looping task that execute a code every few interval
/// - Parameters:
///   - delay: The interval delay
///   - block: The code to be executed
/// - Returns: The task used to create the interval
@discardableResult public func setInterval(delay: UInt64?, _ block: @Sendable @escaping () throws -> Void) -> Task<Void, Error>? {
    guard let delay = delay else {
        return nil
    }
    return Task {
        while !Task.isCancelled {
            try await Task.sleep(nanoseconds: delay)
            try block()
        }
    }
}
