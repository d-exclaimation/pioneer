---
icon: hubot
order: 80
---

# Resolvers and Context

Now, let's get into the resolvers (and context as well), the main logic of the API.

Graphiti require a seperate top level structure acting as the resolver and a context type be given to these resolver functions.

## Context

Let's start with the context. Pioneer will try to build this context on each request by asking for a function that provides both the `Request` and `Response` classes and expects the context instance.

```swift
import Vapor

struct Context {
    var req: Request
    var res: Response
}
```

The context here will very simple which only grab the `Request` and `Response` so we can get certain values from the request and set some to the response.

!!!success Context building with async-await
Since `v0.6.0`, Pioneer can accept async and/or throwing context builder, and this applies to the websocket context builder as well (since `v0.7.0`)
!!!

[!ref Context Building](../../guides/advanced/context)

## Resolver

The resolver will include all the basic CRUD operations. Both Graphiti and Pioneer comes with extensions to `Field` and `SubscriptionField` to allow the use of `async/await` in queries and/or mutations and also `EventStream` built from `AsyncSequence` for subscriptions in the resolvers.

```swift
import Vapor
import Pioneer
import Graphiti

struct Resolver {
    func users(_: Context, _: NoArguments) async -> [User] {
        await Datastore.shared.select()
    }

    struct UserIDArgs: Decodable {
        var id: ID
    }

    func user(_: Context, args: UserIDArgs) async -> [User] {
        await Datastore.shared.find(with: [args.id]).first
    }

    struct AddUserArgs: Decodable {
        var user: UserInput
    }

    func create(_: Context, args: AddUserArgs) async -> User? {
        await Datastore.shared.insert(User(args.user))
    }

    struct UpdateUserArgs: Decodable {
        var id: ID
        var user: UserInput
    }

    func update(_: Context, args: UpdateUserArgs) async -> User? {
        await Datastore.shared.update(for args.id, with: User(id: args.id, args.user))
    }


    func delete(_: Context, args: UserIDArgs) async -> User? {
        await Datastore.shared.delete(for: args.id)
    }

}
```

## Subscriptions

Pioneer has capabilities to handle subscription through websocket, all you need to provide is an `EventStream` that was built with `AsyncSequence`.

```swift
import GraphQL

let ON_CHANGE_TRIGGER = "user-on-change"

struct Resolver {
    let pubsub = AsyncPubSub()

    ...

    func create(_: Context, args: AddUserArgs) async -> User {
        let user = await Datastore.shared.insert(User(id: args.id, args.user))
        if user = user {
            await pubsub.publish(ON_CHANGE_TRIGGER, payload: user)
        }
        return user
    }

    ...

    func update(_: Context, args: UpdateUserArgs) async -> User? {
        let user = await Datastore.shared.update(for: args.id, with: User(args.user))
        if user = user {
            await pubsub.publish(ON_CHANGE_TRIGGER, payload: user)
        }
        return user
    }

    ...

    func onChange(_: Context, _: NoArgs) -> EventStream<User> {
        pubsub
            .asyncStream(User.self, for: ON_CHANGE_TRIGGER)
            .toEventStream()
    }
}
```

!!!warning AsyncSequence and EventStream
Pioneer can only accept `EventStream` built with `AsyncEventStream`, which is an implementation of `EventStream` for any `AsyncSequence`.

Learn why on:

[!ref EventStream](../../features/async-event-stream.md)

!!!

!!!success AsyncPubSub
Pioneer brings a data structure that acts like a in memory PubSub for managing topic/trigger based `AsyncSequence` using Swift `actors` and `AsyncStream`.

The [AsyncPubSub](../../guides/advanced/subscriptions/#asyncpubsub) can generate a new consumer `AsyncStream` of a certain type from a single Source stream differentiated through the trigger string.

==- Example code

```swift
let pubsub = AsyncPubSub()

let asyncStream: AsyncStream<Int> = pubsub
    .asyncStream(for: "my-trigger")

await pubsub.publish(for: "my-trigger", payload: 10)
```

===

!!!

## Relationship

In the part where we declare the User type, we have this `friendIDs` property. This property was there for the base for building a relationship.

You can add a custom resolver by extending the User type with a function that resembles the resolver functions, only here it can access the parent type.

```swift
extension User {
    func friends(_: Context, _: NoArgs) async -> [User] {
        await Datastore.shared.find(with: _friendIDs)
    }
}
```

!!!warning N+1 problem
In an actual application where this request is made to database, it's best to avoid directly making a request in a relationship resolver and use a [Dataloader](https://github.com/GraphQLSwift/DataLoader) instead which helps to avoid unnecessary request for fetching the exact same data.

[!ref N+1 problem](../../guides/advanced/fluent/#n1-problem)

==- Dataloader example

+++ Context and DataLoader

```swift
struct Context {
    ...
    // Loader computed on each Context or each request
    var userLoader: DataLoader<ID, User>
}

// Must use the EventLoopPromise API since DataLoader hasn't migrated over to async/await and Pioneer hasn't added extensions
func makeUserLoader(req: Request) -> DataLoader<ID, User> {
    return .init(on: req.eventLoop) { keys async in
        let res = await Datastore.shared.find(with: keys)
        return keys.map { key in
            guard let value = res.first(where: { $0.id == key }) else {
                return .error(GraphQLError(message: "No item with corresponding key: \(key)"))
            }
            return .success(value)
        }
    }
}

```

+++ Resolver

```swift
extension User {
    func friends(ctx: Context, _: NoArgs, eventLoopGroup: EventLoopGroup) async -> [User] {
        // Get from the DataLoader preventing N+1 problems
        try await ctx.userLoader.loadMany(keys: _friendIDs, on: eventLoopGroup)
    }
}

```

+++ Context builder

```swift
let server = Pioneer(
    ...,
    // Update context builder to create a new loader on each request, preventing loader to invalidly use cache when not supposed to
    contextBuilder: { req, res in
        Context(req: req, res: res, userLoader: makeUserLoader(req: req))
    }
)

```

+++

===

!!!
