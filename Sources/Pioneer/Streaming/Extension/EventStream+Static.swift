//
//  EventStream+Static.swift
//  pioneer
//
//  Created by d-exclaimation on 23:06.
//

import class GraphQL.EventStream

public extension EventStream {
    /// Constructs an AsyncEventStream for an element type, using the specified buffering policy and element-producing closure
    /// - Parameters:
    ///   - elementType: The type of element the AsyncEventStream produces
    ///   - limit: The maximum number of elements to hold in the buffer
    ///   - build: A custom closure that yields values to the AsyncEventStream
    static func `async`(
        _ elementType: Element.Type = Element.self,
        bufferingPolicy limit: AsyncThrowingStream<Element, Error>.Continuation.BufferingPolicy = .unbounded,
        _ build: (AsyncThrowingStream<Element, Error>.Continuation) -> Void
    ) -> AsyncEventStream<Element, AsyncThrowingStream<Element, Error>> {
        .init(from: .init(elementType, bufferingPolicy: limit, build))
    }
}
