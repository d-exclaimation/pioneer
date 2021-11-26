//
//  Jet+EventStream.swift
//  GraphQLAsyncSequence
//
//  Created by d-exclaimation on 3:33 PM.
//  Copyright © 2021 d-exclaimation. All rights reserved.
//

import Desolate
import GraphQL

extension Jet {
    /// Convenient method for creating an EventStream.
    ///
    /// - Returns: EventStream from the produced Nozzle consumer.
    public func eventStream() -> AsyncEventStream<Element, Nozzle<Element>> {
        nozzle().toEventStream()
    }

    /// Detach the AsyncEventStream from the Jet.
    ///
    /// - Parameter eventStream: AsyncEventStream that is using a Nozzle as it's source.
    public func erase(eventStream: AsyncEventStream<Element, Nozzle<Element>>) {
        erase(nozzle: eventStream.sequence)
    }
}
