//
//  Reservoir+EventStream.swift
//  Pioneer
//
//  Created by d-exclaimation on 2:05 PM.
//

import Desolate

extension Reservoir {
    /// Convenient method for creating an EventStream.
    ///
    /// - Parameter key: Key used to find Source from Reservoir
    /// - Returns: An event stream from the nozzle
    public func eventStream(for key: Key) async -> EventSource<Element> {
        await nozzle(for: key).eventStream()
    }
}
