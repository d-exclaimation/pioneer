//  DataLoader+AsyncAwait.swift
//  
//
//  Created by d-exclaimation on 10/06/22.
//

import Foundation
import DataLoader
import Vapor

/// Async-await non-throwing batch loading function
public typealias AsyncgBatchLoadFunction<Key, Value> = (_ keys: [Key]) async -> [DataLoaderFutureValue<Value>]

/// Async-await throwing batch loading function
public typealias AsyncThrowingBatchLoadFunction<Key, Value> = (_ keys: [Key]) async throws -> [DataLoaderFutureValue<Value>]

public extension DataLoader {
    // without throwing
    
    convenience init(
        on req: Request,
        with options: DataLoaderOptions<Key, Value> = DataLoaderOptions(),
        load asyncLoadFunction: @escaping AsyncgBatchLoadFunction<Key, Value>
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
        load asyncLoadFunction: @escaping AsyncgBatchLoadFunction<Key, Value>
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
