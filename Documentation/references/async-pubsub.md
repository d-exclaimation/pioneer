---
icon: rows
order: 90
---

# AsyncPubSub

## AsyncPubSub

AsyncPubSub is a in memory pubsub structure for managing [AsyncStreams](https://developer.apple.com/documentation/swift/asyncstream) in a concurrent safe way utilizing Actors.

!!!success Multiple upstream, multiple data type
AsyncPubSub is a multiple upstream and multiple data type pubsub stream.

**Trigger-based**

The upstream will be differentiated by a trigger, and only consumer stream with the same trigger will receive the emitted data.

**Multi types consumer**

All consumer streams are not restricted to a single data type.
!!!

!!!warning Sendable
At the moment, AsyncPubSub has no restriction to make emitted data and consumer data type to conform to Sendable. However, it's best if they are to avoid data races.

In the future, This restriction (DataType must be Sendable) will be slowly added.
!!!

### `init`

Returns an initialized [AsyncPubSub](#asyncpubsub).

=== Example

```swift
let pubsub = AsyncPubSub()
```

===

### `asyncStream`

Returns a new [AsyncStream](https://developer.apple.com/documentation/swift/asyncstream) with the specified type and for a specific trigger.

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

| Name      | Type                                     | Description                                |
| --------- | ---------------------------------------- | ------------------------------------------ |
| `for`     | [!badge variant="primary" text="String"] | The trigger this data will be published to |
| `payload` | [!badge variant="danger" text="Any"]     | The data being emitted                     |

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
