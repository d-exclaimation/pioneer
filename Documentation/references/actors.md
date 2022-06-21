---
icon: people
order: 50
---

# Actors

## Broadcast

An actor to broadcast messages to multiple downstream from a single upstream

### `init`

Returns an initialized [Broadcast](#broadcast).

=== Example

```swift
let broadcast = Broadcast()
```

===

### `downstream`

Creates a new downstream with an id

=== Example

```swift
let downstream: Downstream<MessageType> = await broadcast.downstream()
```

===

### `publish`

Publish broadcast sendable data to all currently saved consumer

=== Example

```swift
await broadcast.publish(MessageType(content: "Hello world!!"))
```

===

==- Options

| Name    | Type                                         | Description                       |
| ------- | -------------------------------------------- | --------------------------------- |
| `value` | [!badge variant="danger" text="MessageType"] | The sendable data to be published |

===

### `close`

Close shutdowns the entire broadcast and unsubscribe all consumer.

=== Example

```swift
await broadcast.close()
```

===
