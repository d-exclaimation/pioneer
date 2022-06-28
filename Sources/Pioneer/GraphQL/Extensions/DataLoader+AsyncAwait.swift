//  DataLoader+AsyncAwait.swift
//  
//
//  Created by d-exclaimation on 10/06/22.
//

import DataLoader
import class Vapor.Request
import protocol NIO.EventLoop

/// Async-await non-throwing batch loading function
public typealias AsyncBatchLoadFunction<Key, Value> = (_ keys: [Key]) async -> [DataLoaderFutureValue<Value>]

/// Async-await throwing batch loading function
public typealias AsyncThrowingBatchLoadFunction<Key, Value> = (_ keys: [Key]) async throws -> [DataLoaderFutureValue<Value>]

public extension DataLoader {
    // without throwing
    
    convenience init(
        on req: Request,
        with options: DataLoaderOptions<Key, Value> = DataLoaderOptions(),
        load asyncLoadFunction: @escaping AsyncBatchLoadFunction<Key, Value>
    ) {
        self.init(options: options, batchLoadFunction: { keys in
            req.eventLoop.performWithTask {
                await asyncLoadFunction(keys)
            }
        })
    }
    
    convenience init(
        on eventLoop: EventLoop,
        with options: DataLoaderOptions<Key, Value> = DataLoaderOptions(),
        load asyncLoadFunction: @escaping AsyncBatchLoadFunction<Key, Value>
    ) {
        self.init(options: options, batchLoadFunction: { keys in
            eventLoop.performWithTask {
                await asyncLoadFunction(keys)
            }
        })
    }
    
    // with throwing
    
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
    
    convenience init(
        on eventLoop: EventLoop,
        with options: DataLoaderOptions<Key, Value> = DataLoaderOptions(),
        throwing asyncThrowingLoadFunction: @escaping AsyncThrowingBatchLoadFunction<Key, Value>
    ) {
        self.init(options: options, batchLoadFunction: { keys in
            eventLoop.performWithTask {
                try await asyncThrowingLoadFunction(keys)
            }
        })
    }
}
