//  DataLoader+AsyncAwait.swift
//  
//
//  Created by d-exclaimation on 10/06/22.
//

import DataLoader
import class Vapor.Request
import protocol NIO.EventLoop

/// Async-await throwing batch loading function
public typealias AsyncThrowingBatchLoadFunction<Key, Value> = @Sendable (_ keys: [Key]) async throws -> [DataLoaderFutureValue<Value>]

public extension DataLoader {
    convenience init(
        on req: Request,
        with options: DataLoaderOptions<Key, Value> = DataLoaderOptions(),
        throwing asyncThrowingLoadFunction: @escaping AsyncThrowingBatchLoadFunction<Key, Value>
    ) {
        self.init(options: options, batchLoadFunction: { keys in
            req.eventLoop.performWithTask {
                try await asyncThrowingLoadFunction(keys)
            }
        })
    }
}
