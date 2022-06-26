//  Broadcast.swift
//  
//
//  Created by d-exclaimation on 20/06/22.
//

import Foundation

/// An actor to broadcast messages to multiple downstream from a single upstream
public actor Broadcast<MessageType: Sendable> {
    public typealias Consumer = AsyncStream<MessageType>.Continuation
    
    private var consumers: [UUID: Consumer] = [:]
    
    /// Creates a new downstream with an id
    /// - Returns: The async stream and its id
    public func downstream() async -> Downstream<MessageType> {
        Downstream<MessageType> { id, con in
            Task {
                await self.subscribe(id, with: con)
            }
            
            con.onTermination = { @Sendable _ in
                Task {
                    await self.unsubscribe(id)
                }
            }
        }
    }
    
    /// Unsubscribe removed the downstream and prevent it from receiving any further broadcasted data
    /// - Parameter downstream: The key used to identified the consumer
    internal func unsubscribe(_ downstream: Downstream<MessageType>) async {
        consumers.delete(downstream.id)
    }
    
    /// Unsubscribe removed the downstream and prevent it from receiving any further broadcasted data
    /// - Parameter id: The key used to identified the consumer
    internal func unsubscribe(_ id: UUID) async {
        consumers.delete(id)
    }
    
    /// Subscribe saved and set up downstream to receive broadcasted message
    /// - Parameters:
    ///   - id: The key used to identified the consumer
    ///   - consumer: The AsyncStream Continuation as the consumer
    internal func subscribe(_ id: UUID, with downstream: Consumer) async {
        consumers.update(id, with: downstream)
    }

    
    /// Publish broadcast sendable data to all currently saved consumer
    /// - Parameter value: The sendable data to be published
    public func publish(_ value: MessageType) async {
        consumers.values.forEach { consumer in
            consumer.yield(value)
        }
    }
    
    /// Close shutdowns the entire broadcast and unsubscribe all consumer
    public func close() async {
        consumers.values.forEach { consumer in
            consumer.finish()
        }
        consumers.removeAll()
    }

    public init() {}
}

/// An async stream with an id
public struct Downstream<Element: Sendable>: AsyncSequence {
    /// The id of the stream
    public let id: UUID
    /// The stream itself
    public let stream: AsyncStream<Element>
    
    public init(
        _ elementType: Element.Type = Element.self,
        bufferingPolicy limit: AsyncStream<Element>.Continuation.BufferingPolicy = .unbounded,
        _ build: @escaping (UUID, AsyncStream<Element>.Continuation) -> Void
    ) {
        let id = UUID()
        self.id = id
        self.stream = AsyncStream<Element>(elementType, bufferingPolicy: limit) { con in
            build(id, con)
        }
    }
    
    public func makeAsyncIterator() -> AsyncStream<Element>.AsyncIterator {
        stream.makeAsyncIterator()
    }
}
