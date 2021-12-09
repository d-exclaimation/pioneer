//
//  AsyncStream+Statics.swift
//  Pioneer
//
//  Created by d-exclaimation on 10:05 PM.
//  Copyright © 2021 d-exclaimation. All rights reserved.
//

extension AsyncStream {
    /// Create an AsyncStream from a single value
    /// - Parameter value: The only value in this stream
    /// - Returns: The AsyncStream itself
    public static func just(_ value: Element) -> Self {
        .init { con in
            con.yield(value)
            con.finish()
        }
    }
    
    /// Create an AsyncStream from a certain amount of element
    /// - Parameter values: All the elements
    /// - Returns: The AsyncStream itself
    public static func of(_ values: Element...) -> Self {
        .init { con in
            Task {
                values.forEach {
                    con.yield($0)
                }
                con.finish()
            }
        }
    }
    
    /// Create an AsyncStream from an iterable value
    /// - Parameter values: Iterable values
    /// - Returns: The AsyncStream itself
    public static func iterable(_ values: [Element]) -> Self {
        .init { con in
            Task {
                values.forEach {
                    con.yield($0)
                }
                con.finish()
            }
        }
    }
}
