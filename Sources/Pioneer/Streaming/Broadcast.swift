//  ActorPubSub.swift
//  
//
//  Created by d-exclaimation on 20/06/22.
//

import Foundation

/// A PubSub that utilize broadcast hub through an Actor
public protocol Broadcast where Self: PubSub {
    /// Dispatcher is a actor for the pubsub to concurrently manage publishers and incoming data
    associatedtype Dispatcher: Dispatch
    
    /// The dispatcher actor instance
    var dispatcher: Dispatcher { get }
}

/// An actor for a pubsub to concurrently manage publishers, incoming data, and dispatch data
public protocol Dispatch where Self: Actor {
    /// Async stream return a new AsyncStream that is connected to the emitter that is assigned to the given key
    /// - Parameter key: The string topic / key used to find the emitter
    /// - Returns: An async stream that is linked to an emitter
    func asyncStream(for key: String) async -> AsyncStream<Sendable>
    
    /// Publish sends a data to a emitter that is assigned to the given key
    /// - Parameters:
    ///   - key: The string topic / key used to find the emitter
    ///   - value: The sendable data being sent
    func publish(for key: String, _ value: Sendable) async
    
    /// Close shutdowns an emitter that is assigned to the given key
    /// - Parameter key: The string / topic key
    func close(for key: String) async 
}

