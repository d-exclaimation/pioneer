//
//  AsyncSequence+EventStream.swift
//  Pioneer
//
//  Created by d-exclaimation on 3:38 PM.
//

import class GraphQL.EventStream

extension AsyncSequence {
    public typealias Termination = AsyncThrowingStream<Element, Error>.Continuation.Termination
    
    /// Convert Any AsyncSequence to an EventStream for GraphQL Streaming.
    ///
    /// - Returns: EventStream implementation for AsyncSequence.
    public func toEventStream() -> EventStream<Element> {
        AsyncEventStream<Element, Self>(from: self)
    }

    /// Convert any AsyncSequence to an EventStream
    ///
    /// - Parameters:
    ///   - onTermination: onTermination callback
    public func toEventStream(
        onTermination callback: @escaping @Sendable (Termination) -> Void
    ) -> EventStream<Element> {
        let stream = AsyncThrowingStream<Element, Error> { continuation in
            let task = Task.init {
                do {
                    for try await each in self {
                        let element: Element = each
                        continuation.yield(element)
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }

            @Sendable
            func onTermination(_ termination: Termination) {
                callback(termination)
                task.cancel()
            }

            continuation.onTermination = onTermination
        }
        return AsyncEventStream<Element, AsyncThrowingStream<Element, Error>>(from: stream)
    }


    /// Convert any AsyncSequence to an EventStream
    ///
    /// - Parameters:
    ///   - endValue: Ending value
    ///   - onTermination: onTermination callback
    public func toEventStream(
        endValue: @escaping () -> Element,
        onTermination callback: @escaping @Sendable (Termination) -> Void
    ) -> EventStream<Element> {
        let stream = AsyncThrowingStream<Element, Error> { continuation in
            let task = Task.init {
                do {
                    for try await each in self {
                        let element: Element = each
                        continuation.yield(element)
                    }
                    continuation.yield(endValue())
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }

            @Sendable
            func onTermination(_ termination: Termination) {
                callback(termination)
                task.cancel()
            }

            continuation.onTermination = onTermination
        }
        return AsyncEventStream<Element, AsyncThrowingStream<Element, Error>>(from: stream)
    }


    /// Convert any AsyncSequence to an EventStream
    ///
    /// - Parameters:
    ///   - initialValue: Initial value from subscriptions
    ///   - onTermination: onTermination callback
    public func toEventStream(
        initialValue: Element,
        onTermination callback: @escaping @Sendable (Termination) -> Void
    ) -> EventStream<Element> {
        let stream = AsyncThrowingStream<Element, Error> { continuation in
            let task = Task.init {
                do {
                    continuation.yield(initialValue)
                    for try await each in self {
                        let element: Element = each
                        continuation.yield(element)
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }

            @Sendable
            func onTermination(_ termination: Termination) {
                callback(termination)
                task.cancel()
            }

            continuation.onTermination = onTermination
        }
        return AsyncEventStream<Element, AsyncThrowingStream<Element, Error>>(from: stream)
    }

    /// Convert any AsyncSequence to an EventStream
    ///
    /// - Parameters:
    ///   - initialValue: Initial value from subscriptions
    ///   - endValue: Ending value
    ///   - onTermination: onTermination callback
    public func toEventStream(
        initialValue: Element,
        endValue: @escaping () -> Element,
        onTermination callback: @escaping @Sendable (Termination) -> Void
    ) -> EventStream<Element> {
        let stream = AsyncThrowingStream<Element, Error> { continuation in
            let task = Task.init {
                do {
                    continuation.yield(initialValue)
                    for try await each in self {
                        let element: Element = each
                        continuation.yield(element)
                    }
                    continuation.yield(endValue())
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }

            @Sendable
            func onTermination(_ termination: Termination) {
                callback(termination)
                task.cancel()
            }

            continuation.onTermination = onTermination
        }
        return AsyncEventStream<Element, AsyncThrowingStream<Element, Error>>(from: stream)
    }
    
    /// Convert any AsyncSequence to an EventStream
    ///
    /// - Parameters:
    ///   - initialValue: Initial value from subscriptions
    ///   - endValue: Ending value
    public func toEventStream(
        initialValue: Element,
        endValue: @escaping () -> Element
    ) -> EventStream<Element> {
        let stream = AsyncThrowingStream<Element, Error> { continuation in
            let task = Task.init {
                do {
                    continuation.yield(initialValue)
                    for try await each in self {
                        let element: Element = each
                        continuation.yield(element)
                    }
                    continuation.yield(endValue())
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }

            @Sendable
            func onTermination(_: Termination) {
                task.cancel()
            }

            continuation.onTermination = onTermination
        }
        return AsyncEventStream<Element, AsyncThrowingStream<Element, Error>>(from: stream)
    }
}
