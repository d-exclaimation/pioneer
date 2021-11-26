//
//  AsyncSequence+EventStream.swift
//  Pioneer
//
//  Created by d-exclaimation on 3:38 PM.
//  Copyright © 2021 d-exclaimation. All rights reserved.
//

extension AsyncSequence {
    /// Convert Any AsyncSequence to an EventStream for GraphQL Subscription.
    ///
    /// - Returns: EventStream implementation for AsyncSequence.
    public func toEventStream() -> AsyncEventStream<Element, Self> {
        .init(from: self)
    }
}