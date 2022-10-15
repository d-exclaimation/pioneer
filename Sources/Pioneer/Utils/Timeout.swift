//
//  Timeout.swift
//  pioneer
//
//  Created by d-exclaimation on 10:23.
//

/// Create a delay for an execution of a code
/// - Parameters:
///   - delay: The delay before the code is executed
///   - block: The code to be executed
/// - Returns: The task used for the delay
@discardableResult func setTimeout(delay: UInt64?, _ block: @Sendable @escaping () async throws -> Void) -> Task<Void, Error>? {
    guard let delay = delay else {
        return nil
    } 
    return Task {
        try await Task.sleep(nanoseconds: delay)
        guard !Task.isCancelled else {
            return
        }
        try await block()
    }
}