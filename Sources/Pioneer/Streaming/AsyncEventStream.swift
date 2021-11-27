//
//  AsyncEventStream.swift
//  Pioneer
//
//  Created by d-exclaimation on 3:17 PM.
//  Copyright © 2021 d-exclaimation. All rights reserved.
//

import GraphQL
import Desolate

/// EventStream implementation for AsyncSequence for allowing GraphQL Streaming.
public class AsyncEventStream<Element, Sequence: AsyncSequence>: EventStream<Element> where Sequence.Element == Element {
    /// Inner AsyncSequence
    public let sequence: Sequence

    public init(from: Sequence) {
        sequence = from
    }

    /// Override transforming method.
    ///
    /// - Parameter closure: Transformation closure.
    /// - Returns: A new EventStream with the new type.
    override open func map<To>(_ closure: @escaping (Element) throws -> To) -> EventStream<To> {
        let (stream, engine) = Nozzle<To>.desolate()
        Task.init {
            for try await each in self.sequence {
                let res = try closure(each)
                await engine.task(with: res)
            }
            await engine.task(with: .none)
        }
        return AsyncEventStream<To, Nozzle<To>>.init(from: stream)
    }
}



