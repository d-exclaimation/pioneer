//
//  AsyncPubSub.swift
//  Pioneer
//
//  Created by d-exclaimation.
//

/// AsyncPubSub is a in memory pubsub structure for managing AsyncStreams in a concurrent safe way utilizing Actors.
public struct AsyncPubSub: PubSub, Sendable {
    public typealias Producer = Broadcast<Sendable>
    
    /// Dispatcher is a actor for the pubsub to concurrently manage publishers and incoming data
    public actor Dispatcher {
        private var emitters: [String: Producer] = [:]
        
        /// Subscribe get the emitters that is assigned to the given key 
        /// - Parameter key: The string topic / key used to differentiate emitters
        /// - Returns: The emitters stored or a new one 
        internal func subscribe(for key: String) async -> Producer {
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
            let downstream = await emitter.downstream()
            return downstream.stream
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
    
    public let dispatcher: Dispatcher = .init()
    
    public init() {}
    
    /// Returns a new AsyncStream with the correct type and for a specific trigger
    ///
    /// - Parameters:
    ///   - type: DataType of this AsyncStream
    ///   - trigger: The topic string used to differentiate what data should this stream be accepting
    public func asyncStream<DataType: Sendable & Decodable>(_ type: DataType.Type = DataType.self, for trigger: String) -> AsyncStream<DataType> {
        AsyncStream<DataType> { con in
            let task = Task {
                let pipe = await dispatcher.asyncStream(for: trigger)
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
    public func publish<DataType: Sendable & Encodable>(for trigger: String, payload: DataType) async {
        await dispatcher.publish(for: trigger, payload)
    }
    
    /// Close a specific trigger and deallocate every consumer of that trigger
    /// - Parameter trigger: The trigger this call takes effect on
    public func close(for trigger: String) async {
        await dispatcher.close(for: trigger)
    }
}
