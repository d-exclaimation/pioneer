---
icon: cpu
order: 60
---

# Protocols

## PubSub

A base protocol for pub/sub data structure that utilize async stream

!!!info Multiple topic
If implemented properly, PubSub should be able to handle multiple topic where each topic can have multiple downstream
!!!

!!!info Sendable, Encodable, and Decodable
PubSub only accept data type that conforms to the `Sendable` protocol to avoid any memory issues related to concurrency.

From [PubSub](/references/protocols/#pubsub) conformance, the data type has to be either `Decodable` (for [`asyncStream`](#asyncstream)) and `Encodable` (for [`publish`](#publish)) so it can always be encoded and decoded properly.
!!!

!!!success AsyncPubSub
If you are looking for an implementation, take a look at [`AsyncPubSub`](/references/async-pubsub)
!!!

### `asyncStream`

Returns a new [AsyncStream](https://developer.apple.com/documentation/swift/asyncstream) with the specified type and for a specific trigger.

!!!info Downstream
If implemented properly, this method should returns a downstream that can be unsubscribed from the pubsub without affecting other downstreams.
!!!

=== Example

```swift
let asyncStream: AsyncStream<Message> = pubsub
    .asyncStream(Message.self, for: "trigger-1")
```

===

==- Options

| Name  | Type                                       | Description                                                                                 |
| ----- | ------------------------------------------ | ------------------------------------------------------------------------------------------- |
| `_`   | [!badge variant="success" text="DataType"] | The specified type for this instance of AsyncStream <br/> **Default:** Inferred if possible |
| `for` | [!badge variant="primary" text="String"]   | Trigger string used to differentiate what data should this stream be accepting              |

===

### `publish`

Publish a new data into the pubsub for a specific trigger.

=== Example

```swift
await pubsub.publish(
    for: "trigger-1",
    payload: Message(content: "Hello world!!")
)
```

===

==- Options

| Name      | Type                                       | Description                                |
| --------- | ------------------------------------------ | ------------------------------------------ |
| `for`     | [!badge variant="primary" text="String"]   | The trigger this data will be published to |
| `payload` | [!badge variant="success" text="DataType"] | The data being emitted                     |

===

### `close`

Close a specific trigger and deallocate every consumer (AsyncStream will be terminated and disposed) of that trigger.

=== Example

```swift
await pubsub.close(
    for: "trigger-1",
)
```

===

==- Options

| Name  | Type                                     | Description                           |
| ----- | ---------------------------------------- | ------------------------------------- |
| `for` | [!badge variant="primary" text="String"] | The trigger this call takes effect on |

===
