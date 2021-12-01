//
//  AbstractDesolate+EventLoopFuture.swift
//  Pioneer
//
//  Created by d-exclaimation on 11:41 PM.
//  Copyright © 2021 d-exclaimation. All rights reserved.
//

import Foundation
import NIO

extension AbstractDesolate {
    /// Method for handling NIO EventLoopFuture with a Behavior `onMessage` using the pipe pattern
    ///
    /// - Parameters:
    ///   - future: EventLoopFuture value being awaited
    ///   - transform: Transforming callback to turn future value into a Behavior message.
    public func pipeToSelf<U>(future: EventLoopFuture<U>, to transform: @escaping (Result<U, Error>) -> MessageType) {
        let task = Task.init { () async throws -> U in
            try await future.get()
        }
        pipeToSelf(task, into: transform)
    }
}