//
//  AsyncSequence+EventStream.swift
//  Pioneer
//
//  Created by d-exclaimation on 3:38 PM.
//  Copyright © 2021 d-exclaimation. All rights reserved.
//

import GraphQL

extension AsyncSequence {
    /// Convert Any AsyncSequence to an EventStream for GraphQL Streaming.
    ///
    /// - Returns: EventStream implementation for AsyncSequence.
    public func toEventStream() -> EventStream<Element> {
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
        onTermination: @escaping @Sendable () -> Void
    ) -> EventStream<Element> {
        let (new, desolate) = Nozzle<Element>.desolate()
        Task.init {
            for try await each in self {
                await desolate.task(with: each)
            }
            await desolate.task(with: .none)
        }
        defer {
            new.onTermination(onTermination)
        }
        return EventNozzle<Element>(from: new)
    }


    /// Convert any AsyncSequence to an EventStream
    ///
    /// - Parameters:
    ///   - endValue: Ending value
    ///   - onTermination: onTermination callback
    public func toEventStream(
        endValue: @escaping () -> Element,
        onTermination: @escaping @Sendable () -> Void
    ) -> EventStream<Element> {
        let (new, desolate) = Nozzle<Element>.desolate()
        Task.init {
            for try await each in self {
                await desolate.task(with: each)
            }
            await desolate.task(with: endValue())
            await desolate.task(with: .none)
        }
        defer {
            new.onTermination(onTermination)
        }
        return EventNozzle<Element>(from: new)
    }


    /// Convert any AsyncSequence to an EventStream
    ///
    /// - Parameters:
    ///   - initialValue: Initial value from subscriptions
    ///   - onTermination: onTermination callback
    public func toEventStream(
        initialValue: Element,
        onTermination: @escaping @Sendable () -> Void
    ) -> EventStream<Element> {
        let (new, desolate) = Nozzle<Element>.desolate()
        Task.init {
            await desolate.task(with: initialValue)
            for try await each in self {
                await desolate.task(with: each)
            }
            await desolate.task(with: .none)
        }
        defer {
            new.onTermination(onTermination)
        }
        return EventNozzle<Element>(from: new)
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
        onTermination: @escaping @Sendable () -> Void
    ) -> EventStream<Element> {
        let (new, desolate) = Nozzle<Element>.desolate()
        Task.init {
            await desolate.task(with: initialValue)
            for try await each in self {
                await desolate.task(with: each)
            }
            await desolate.task(with: endValue())
            await desolate.task(with: .none)
        }
        defer {
            new.onTermination(onTermination)
        }
        return EventNozzle<Element>(from: new)
    }
}

extension Nozzle {
    /// Convert Any AsyncSequence to an EventStream for GraphQL Streaming.
    ///
    /// - Returns: EventStream implementation for Nozzle.
    public func eventStream() -> EventNozzle<Element> {
        .init(from: self)
    }
}