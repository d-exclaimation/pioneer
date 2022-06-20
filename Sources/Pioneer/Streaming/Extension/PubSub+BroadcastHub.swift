//  PubSub+BroadcastHub.swift
//  
//
//  Created by d-exclaimation on 20/06/22.
//

import Foundation

extension PubSub where Self: BroadcastHub {
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
}
