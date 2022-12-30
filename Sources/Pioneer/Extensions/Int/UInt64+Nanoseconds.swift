//
//  UInt64+Nanoseconds.swift
//  pioneer
//
//  Created by d-exclaimation on 14:19.
//

public extension Optional where WrappedType == UInt64 {
    /// Convert the given value in seconds into nanoseconds
    /// - Parameter s: The value in seconds
    /// - Returns: The nanoseconds result
    static func seconds(_ s: UInt64) -> UInt64 {
        s * 1_000_000_000
    }

    /// Convert the given value in milliseconds into nanoseconds
    /// - Parameter s: The value in milliseconds
    /// - Returns: The nanoseconds result
    static func milliseconds(_ s: UInt64) -> UInt64 {
        s * 1_000_000
    }

    /// Convert the given value in microseconds into nanoseconds
    /// - Parameter s: The value in microseconds
    /// - Returns: The nanoseconds result
    static func microseconds(_ s: UInt64) -> UInt64 {
        s * 1000
    }
}
