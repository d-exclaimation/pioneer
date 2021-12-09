//
//  AsyncSequence+EventStream.swift
//  Pioneer
//
//  Created by d-exclaimation on 3:38 PM.
//  Copyright © 2021 d-exclaimation. All rights reserved.
//

extension AsyncSequence {
    /// Convert Any AsyncSequence to an EventStream for GraphQL Streaming.
    ///
    /// - Returns: EventStream implementation for AsyncSequence.
    public func toEventStream() -> EventSource<Element> {
        if let nozzle = self as? Nozzle<Element> {
            return nozzle.eventStream()
        }
        return AsyncEventStream<Element, Self>(from: self)
    }

    /// Convert any AsyncSequence to an EventStream
    ///
    /// - Parameters:
    ///   - onTermination: onTermination callback
    public func toEventStream(
        onTermination callback: @escaping @Sendable () -> Void
    ) -> EventSource<Element> {
        let stream = AsyncStream<Element> { continuation in
            let task = Task.init {
                do {
                    for try await each in self {
                        let element: Element = each
                        continuation.yield(element)
                    }
                    continuation.finish()
                } catch {
                    continuation.finish()
                }
            }

            @Sendable
            func onTermination(_: AsyncStream<Element>.Continuation.Termination) {
                callback()
                task.cancel()
            }

            continuation.onTermination = onTermination
        }
        return AsyncEventStream<Element, AsyncStream<Element>>.init(from: stream)
    }


    /// Convert any AsyncSequence to an EventStream
    ///
    /// - Parameters:
    ///   - endValue: Ending value
    ///   - onTermination: onTermination callback
    public func toEventStream(
        endValue: @escaping () -> Element,
        onTermination callback: @escaping @Sendable () -> Void
    ) -> EventSource<Element> {
        let stream = AsyncStream<Element> { continuation in
            let task = Task.init {
                do {
                    for try await each in self {
                        let element: Element = each
                        continuation.yield(element)
                    }
                    continuation.yield(endValue())
                    continuation.finish()
                } catch {
                    continuation.finish()
                }
            }

            @Sendable
            func onTermination(_: AsyncStream<Element>.Continuation.Termination) {
                callback()
                task.cancel()
            }

            continuation.onTermination = onTermination
        }
        return AsyncEventStream<Element, AsyncStream<Element>>.init(from: stream)
    }


    /// Convert any AsyncSequence to an EventStream
    ///
    /// - Parameters:
    ///   - initialValue: Initial value from subscriptions
    ///   - onTermination: onTermination callback
    public func toEventStream(
        initialValue: Element,
        onTermination callback: @escaping @Sendable () -> Void
    ) -> EventSource<Element> {
        let stream = AsyncStream<Element> { continuation in
            let task = Task.init {
                do {
                    continuation.yield(initialValue)
                    for try await each in self {
                        let element: Element = each
                        continuation.yield(element)
                    }
                    continuation.finish()
                } catch {
                    continuation.finish()
                }
            }

            @Sendable
            func onTermination(_: AsyncStream<Element>.Continuation.Termination) {
                callback()
                task.cancel()
            }

            continuation.onTermination = onTermination
        }
        return AsyncEventStream<Element, AsyncStream<Element>>.init(from: stream)
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
        onTermination callback: @escaping @Sendable () -> Void
    ) -> EventSource<Element> {
        let stream = AsyncStream<Element> { continuation in
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
                    continuation.finish()
                }
            }

            @Sendable
            func onTermination(_: AsyncStream<Element>.Continuation.Termination) {
                callback()
                task.cancel()
            }

            continuation.onTermination = onTermination
        }
        return AsyncEventStream<Element, AsyncStream<Element>>.init(from: stream)
    }
    
    /// Convert any AsyncSequence to an EventStream
    ///
    /// - Parameters:
    ///   - initialValue: Initial value from subscriptions
    ///   - endValue: Ending value
    public func toEventStream(
        initialValue: Element,
        endValue: @escaping () -> Element
    ) -> EventSource<Element> {
        let stream = AsyncStream<Element> { continuation in
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
                    continuation.finish()
                }
            }

            @Sendable
            func onTermination(_: AsyncStream<Element>.Continuation.Termination) {
                task.cancel()
            }

            continuation.onTermination = onTermination
        }
        return AsyncEventStream<Element, AsyncStream<Element>>.init(from: stream)
    }
}

extension Nozzle {
    /// Convert nozzle into async sequence
    ///
    /// - Returns: AsyncStream with the same element
    public func asyncStream() -> AsyncStream<Element> {
        AsyncStream { continuation in
            let task = Task.init {
                for await each in self {
                    let element: Element = each
                    continuation.yield(element)
                }
                continuation.finish()
            }

            @Sendable
            func onTermination(_: AsyncStream<Element>.Continuation.Termination) {
                shutdown()
                task.cancel()
            }

            continuation.onTermination = onTermination
        }
    }

    /// Convert Any AsyncSequence to an EventStream for GraphQL Streaming.
    ///
    /// - Returns: EventStream implementation.
    public func eventStream() -> EventSource<Element> {
        AsyncEventStream<Element, AsyncStream<Element>>.init(from: asyncStream())
    }
}
