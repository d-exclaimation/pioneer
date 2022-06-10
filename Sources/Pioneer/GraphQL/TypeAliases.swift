//  TypeAliases.swift
//  
//
//  Created by d-exclaimation on 10/06/22.
//

import Foundation

public typealias _ID = ID
public typealias _GraphQLRequest = GraphQLRequest
public typealias _GraphQLMessage = GraphQLMessage
public typealias _AsyncEventStream = AsyncEventStream
public typealias _AsyncPubSub = AsyncPubSub

public extension Pioneer {
    /// An alias for ``Pioneer/ID``
    typealias ID = _ID
    
    /// An alias for ``Pioneer/GraphQLRequest``
    typealias GraphQLRequest = _GraphQLRequest
    
    /// An alias for ``Pioneer/GraphQLMessage``
    typealias GraphQLMessage = _GraphQLMessage
    
    /// An alias for ``Pioneer/AsyncEventStream``
    typealias AsyncEventStream = _AsyncEventStream
    
    /// An alias for ``Pioneer/AsyncPubSub``
    typealias AsyncPubSub = _AsyncPubSub
}


