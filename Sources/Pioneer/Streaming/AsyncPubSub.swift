//
//  AsyncPubSub.swift
//  Pioneer
//
//  Created by d-exclaimation.
//

import Foundation

/// AsyncPubSub is a in memory pubsub structure for managing AsyncStreams in a concurrent safe way utilizing Actors.
public struct AsyncPubSub: Sendable {
    public typealias Consumer = AsyncStream<Sendable>.Continuation
    
    /// Engine is a actor for the pubsub to concurrently manage emitters and incoming data
    public actor Engine {
        private var emitters: [String: Emitter] = [:]
        
        /// Subscribe get the emitters that is assigned to the given key 
        /// - Parameter key: The string topic / key used to differentiate emitters
        /// - Returns: The emitters stored or a new one 
        internal func subscribe(for key: String) async -> Emitter {
            let emitter = emitters.getOrElse(key) {
                .init()
            }
            emitters.update(key, with: emitter)
            return emitter
        }
        
        /// Async stream return a new AsyncStream that is connected to the emitter that is assigned to the given key
        /// - Parameter key: The string topic / key used to find the emitter
        /// - Returns: An async stream that is linked to an emitter
        internal func asyncStream(for key: String) async -> AsyncStream<Sendable> {
            let emitter = await subscribe(for: key)
            let id = UUID().uuidString.lowercased()
            return AsyncStream<Sendable> { con in
                con.onTermination = { @Sendable _ in
                    Task {
                        await emitter.unsubscribe(id)
                    }
                }
                
                Task {
                    await emitter.subscribe(id, with: con)
                }
            }
            
        }
        
        /// Publish sends a data to a emitter that is assigned to the given key
        /// - Parameters:
        ///   - key: The string topic / key used to find the emitter
        ///   - value: The sendable data being sent
        internal func publish(for key: String, _ value: Sendable) async {
            await emitters[key]?.publish(value)
        }
        
        /// Close shutdowns an emitter that is assigned to the given key
        /// - Parameter key: The string / topic key
        internal func close(for key: String) async {
            await emitters[key]?.close()
            emitters.delete(key)
        }
        
    }
    
    /// Emitter is an actor handling a single type, single topic, and multiple consumer concurrent data broadcasting
    public actor Emitter {
        private var consumers: [String: Consumer] = [:]
        
        /// Subscribe saved and set up Consumer to receive broadcasted Sendable data
        /// - Parameters:
        ///   - key: The key used to identified the consumer
        ///   - consumer: The AsyncStream Continuation as the consumer
        internal func subscribe(_ key: String, with consumer: Consumer) {
            consumers.update(key, with: consumer)
        }

        /// Unsubscribe removed the Consumer and prevent it from receiving any further broadcasted data
        /// - Parameter key: The key used to identified the consumer
        internal func unsubscribe(_ key: String) {
            consumers.delete(key)
        }
        
        /// Publish broadcast sendable data to all currently saved consumer
        /// - Parameter value: The sendable data to be published
        internal func publish(_ value: Sendable) {
            consumers.values.forEach { consumer in
                consumer.yield(value)
            }
        }
        
        /// Close shutdowns the entire emitter and unsubscribe all consumer
        internal func close() {
            consumers.values.forEach { consumer in
                consumer.finish()
            }
            consumers.removeAll()
        }
    }
    
    private let engine: Engine = .init()
    
    /// Returns a new AsyncStream with the correct type and for a specific trigger
    ///
    /// - Parameters:
    ///   - type: DataType of this AsyncStream
    ///   - trigger: The topic string used to differentiate what data should this stream be accepting
    public func asyncStream<DataType: Sendable>(_ type: DataType.Type = DataType.self, for trigger: String) -> AsyncStream<DataType> {
        AsyncStream<DataType> { con in
            let task = Task {
                let pipe = await engine.asyncStream(for: trigger)
                for await untyped in pipe {
                    guard let typed = untyped as? DataType else { continue }
                    con.yield(typed)
                }
                con.finish()
            }
            con.onTermination = { @Sendable _ in
                task.cancel()
            }
        }
    }
    
    /// Publish a new data into the pubsub for a specific trigger.
    /// - Parameters:
    ///   - trigger: The trigger this data will be published to
    ///   - payload: The data being emitted
    public func publish(for trigger: String, payload: Sendable) async {
        await engine.publish(for: trigger, payload)
    }
    
    /// Close a specific trigger and deallocate every consumer of that trigger
    /// - Parameter trigger: The trigger this call takes effect on
    public func close(for trigger: String) async {
        await engine.close(for: trigger)
    }

    public init() {}
}
