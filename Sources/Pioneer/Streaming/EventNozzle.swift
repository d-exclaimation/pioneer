//
//  EventNozzle.swift
//  Pioneer
//
//  Created by d-exclaimation on 4:29 PM.
//  Copyright © 2021 d-exclaimation. All rights reserved.
//

import GraphQL
import Desolate

/// A Memory leak safe toggleable and controllable event stream using Nozzle
public class EventNozzle<Element>: EventStream<Element> {
    public let nozzle: Nozzle<Element>

    init(from: Nozzle<Element>) {
        nozzle = from
    }

    /// Override transforming method.
    ///
    /// - Parameter closure: Transformation closure.
    /// - Returns: A new EventStream with the new type.
    override open func map<To>(_ closure: @escaping (Element) throws -> To) -> EventStream<To> {
        let (new, desolate) = Nozzle<To>.desolate()
        Task.init {
            for await each in nozzle {
                let res = try closure(each)
                await desolate.task(with: res)
            }
            await desolate.task(with: .none)
        }
        defer {
            new.onTermination { [weak self] in
                self?.nozzle.shutdown()
            }
        }
        return EventNozzle<To>.init(from: new)
    }
}

public typealias EventSource<Element> = EventStream<Element>