//
//  Jet+EventStream.swift
//  Pioneer
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
    public func eventStream() -> EventStream<Element> {
        nozzle().eventStream()
    }
}
