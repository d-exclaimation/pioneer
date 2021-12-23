---
icon: package-dependents
order: 90
---

# EventStream

Swift 5.5 brought in a reactive stream like feature in the form of a protocol named `AsyncSequence`.

[GraphQLSwift/GraphQL](https://github.com/GraphQLSwift/GraphQL) required a implementaion of `EventStream` built with any reactive stream like data structure to process subscription operations.

## AsyncEventStream

Pioneer provide an implementation of `EventStream` named `AsyncEventStream` that takes a generic `AsyncSequence`. This mean you can create an event stream using this class from any `AsyncSequence`.

```swift
let eventStream: EventStream<Int> = AsyncEventStream<Int, MyIntAsyncSequence>(
    from: MyIntAsyncSequence()
)
```

### Extensions for AsyncSequence

Converting can be done as well with using the extended method for all `AsyncSequence`. In fact, this is the recommended approach as there are a couple additional features you can add while converting.

```swift
let eventStream = AsyncStream<Int>(...)
    .toEventStream()

// Initial value before any stream values
let eventStream1 = AsyncStream<Int>(...)
    .toEventStream(initialValue: 0)

// End value after stream finishes (excluding termination and value is lazily loaded; hence the function there)
let eventStream2 = AsyncStream<Int>(...)
    .toEventStream(initialValue: 0, endValue: { 10 })
```

## Limitations

### Type casting limitations

One of the problem occured with requiring a protocol instead of a concrete type, is the additional generic which may lead to deeply nested generics.

!!!warning EventStream limit
`EventStream` by itself can't do much beside allowing transforming the value of the stream, and it's recommended to cast the `EventStream` to a concrete type.
!!!

Due to that, Pioneer will use `AsyncStream` when transforming stream values instead of using the built-in `.compactMap` method to avoid deeply uncastable type.

==- .map and .compactMap type results

```swift
let asyncStream: AsyncStream<Int>

let asyncStream1: AsyncMapSequence<AsyncStream<Int>, Int> = asyncStream.map { $0 + 1 }

let asyncStream2: AsyncThrowingCompactMapSequence<AsyncMapSequence<AsyncStream<Int>, Data>, String> = asyncStream.compactMap { try JSONEncoder().encode($0) }
```

===

### Termination callback

By default, `AsyncEventStream` will cancel the task consuming the provided `AsyncSequence` when converting to an `AsyncStream` of a different type. For something like `AsyncStream`, this cancellation will trigger its termination callback so resources can be deallocated and prevent memory leaks of any kind.

However, a custom `AsyncSequence` might have a different trigger and approach in termination. Hence, it's best to explicit provide a termination callback when converting to `EventStream`.

```swift
let eventStream = MyAsyncSequence().toEventStream(
    onTermination: { termination in
        if case .cancelled = termination {
            // do something
        }
    }
)
```

!!!info Termination enum
In the termination callback, you are provided with `AsyncStream.Continuation.Termination` enum that specify the two cases where termination can occur.
!!!

Cases where stream is no longer consumed / stopped and termination will require to be triggered:

- Stream ended itself
- Client send a explicit stop request to end the subscription (might be before stream ended)
- Client disconnect and implicitly stop any running subscription

!!!success AsyncStream and AsyncPubSub
Termination callback can be implicitly inferred for these types of `AsyncSequence`:

- `AsyncStream`
- `AsyncPubSub` (_due to `AsyncStream`_)

+++ AsyncPubSub

```swift
let pubsub = AsyncPubSub()

// Using the PubSub's termination without specifying
let eventStream: EventStream<Message> = await pubsub
    .asyncStream(Message.self, for: "some-topic") // AsyncStream<Message>
    .toEventStream()                          // AsyncEventStream<Message, AsyncStream<Message>>
```

+++ AsyncStream

```swift
let stream = AsyncStream<Quake> { con in
    let monitor = QuakeMonitor()
    monitor.quakeHandler = { quake in
        continuation.yield(quake)
    }
    continuation.onTermination = { @Sendable _ in
        monitor.stopMonitoring()
    }
    monitor.startMonitoring()
}

// Using the AsyncStream's termination without specifying
let eventStream: EventStream<Quake> = stream
    .toEventStream() // AsyncEventStream<Quake, AsyncStream<Quake>>
```

+++

!!!
