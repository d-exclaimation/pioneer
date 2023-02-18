//
//  TestConsumer.swift
//  Pioneer
//
//  Created by d-exclaimation on 10:17 PM.
//  Copyright © 2021 d-exclaimation. All rights reserved.
//

import Foundation
import NIO
import NIOWebSocket
@testable import Pioneer

struct TestConsumer: WebSocketable {
    var buffer: Buffer = .init()

    actor Buffer {
        var store: [String] = []

        func set(_ s: String) async {
            store.append(s)
            try? await Task.sleep(nanoseconds: 0)
        }

        func pop() -> String? {
            guard !store.isEmpty else { return nil }
            return store.removeFirst()
        }

        func popAll() -> [String] {
            store
        }
    }

    func out<S>(_ msg: S) where S: Collection, S.Element == Character {
        guard let str = msg as? String else { return }
        Task.init {
            await buffer.set(str)
        }
    }

    func terminate(code _: WebSocketErrorCode) async throws {}

    func wait() async -> String {
        await withCheckedContinuation { continuation in
            Task.init {
                while true {
                    if let res = await buffer.pop() {
                        continuation.resume(returning: res)
                        return
                    }
                    try? await Task.sleep(nanoseconds: 0)
                }
            }
        }
    }

    func waitAll() async -> [String] {
        await withCheckedContinuation { continuation in
            Task.init {
                continuation.resume(returning: await buffer.popAll())
            }
        }
    }

    func waitAllWithValue(requirement: Int = 1) async -> [String] {
        await withCheckedContinuation { continuation in
            Task.init {
                while true {
                    let res = await buffer.popAll()
                    if abs(res.startIndex - res.endIndex) >= requirement {
                        continuation.resume(returning: res)
                        return
                    }
                    try? await Task.sleep(nanoseconds: 0)
                }
            }
        }
    }

    func waitUntil(time: TimeInterval) async -> String? {
        let start = Date()
        var res = String?.none
        while abs(start.timeIntervalSinceNow) < time {
            res = await buffer.pop()
        }
        return res
    }
}
