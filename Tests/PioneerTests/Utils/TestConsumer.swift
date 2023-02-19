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

/// A test websocket client that synchronous stores message send out in a concurent-safe manner
actor TestClient: WebSocketable {
    /// Push queue
    private var push: [String] = []
    /// Pull queue
    private var pull: [(String) -> Void] = []

    /// Pull many messages from the queue (wait till completion)
    func pullMany(of count: Int = 1) async -> [String] {
        var res: [String] = []
        for _ in 0 ..< count {
            await res.append(pull())
        }
        return res
    }

    /// Pull a message from the queue (wait till completion)
    func pull() async -> String {
        await withCheckedContinuation { [unowned self] continuation in
            self.unshift(using: continuation)
        }
    }

    /// Pull a message until a certain time
    func pull(until time: TimeInterval) async -> String? {
        let start = Date()
        var res = String?.none
        while abs(start.timeIntervalSinceNow) < time {
            res = push.first
            // reset cycle and prevents too much busy waiting
            await Task.yield()
        }
        return res
    }

    /// Push a message to the queue
    func push(_ s: String) {
        if !pull.isEmpty {
            let pulling = pull.removeFirst()
            pulling(s)
            return
        }
        push.append(s)
    }

    /// Nonisolated version of unshift
    private nonisolated func unshift(using continuation: CheckedContinuation<String, Never>) {
        Task { [unowned self] in
            await self.unshift(continuation: continuation)
        }
    }

    /// Pull a message from the queue or await for a message to be pushed
    private func unshift(continuation: CheckedContinuation<String, Never>) async {
        if !push.isEmpty {
            continuation.resume(returning: push.removeFirst())
            return
        }
        pull.append { res in
            continuation.resume(returning: res)
        }
    }

    /// Empty the queue
    private func empty() {
        pull.forEach { $0("") }
        push.removeAll()
        pull.removeAll()
    }

    nonisolated func out<S>(_ msg: S) where S: Collection, S.Element == Character {
        guard let str = msg as? String else { return }
        Task { [unowned self] in
            await Task.yield()
            await self.push(str)
        }
    }

    func terminate(code _: WebSocketErrorCode) async throws {
        empty()
    }
}
