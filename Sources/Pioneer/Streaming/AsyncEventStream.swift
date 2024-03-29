//
//  AsyncEventStream.swift
//  Pioneer
//
//  Created by d-exclaimation on 3:17 PM.
//

import class GraphQL.EventStream

/// EventStream implementation for AsyncSequence for allowing GraphQL Streaming.
public final class AsyncEventStream<Element, Sequence: AsyncSequence>: EventStream<Element> where Sequence.Element == Element {
    /// Inner AsyncSequence
    public let sequence: Sequence

    public init(from: Sequence) {
        sequence = from
    }

    /// Override transforming method.
    ///
    /// - Parameter closure: Transformation closure.
    /// - Returns: A new EventStream with the new type.
    override public func map<To>(_ closure: @escaping (Element) throws -> To) -> EventStream<To> {
        /// Use AsyncStream as bridging instead of the built-in map function to allow for type casting
        /// as using `map` will make the type too complicated to be casted to any meaningful value
        /// Performance and efficiency has been tested to mostly not affected but do keep in mind to try to find a better solution.
        let stream = AsyncThrowingStream(To.self) { continuation in
            let task = Task {
                do {
                    for try await each in self.sequence {
                        let res = try closure(each)
                        continuation.yield(res)
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }

            continuation.onTermination = { @Sendable _ in
                task.cancel()
            }
        }
        return AsyncEventStream<To, AsyncThrowingStream<To, Error>>.init(from: stream)
    }
}

public extension AsyncEventStream where Sequence == AsyncThrowingStream<Element, Error> {
    /// Constructs an AsyncEventStream for an element type, using the specified buffering policy and element-producing closure
    /// - Parameters:
    ///   - elementType: The type of element the AsyncEventStream produces
    ///   - limit: The maximum number of elements to hold in the buffer
    ///   - build: A custom closure that yields values to the AsyncEventStream
    convenience init(
        _ elementType: Element.Type = Element.self,
        bufferingPolicy limit: AsyncThrowingStream<Element, Error>.Continuation.BufferingPolicy = .unbounded,
        _ build: (AsyncThrowingStream<Element, Error>.Continuation) -> Void
    ) {
        self.init(from: .init(elementType, bufferingPolicy: limit, build))
    }
}
