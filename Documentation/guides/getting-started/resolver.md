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

## Resolver

The resolver will include all the basic CRUD operations. Pioneer comes with extensions to Graphiti to allow the use of `async/await` in queries and/or mutations and also `EventStream` built from `AsyncSequence` for subscriptions in the resolvers.

```swift
import Pioneer
import Vapor

struct Resolver {
    func users(_: Context, _: NoArgs) async -> [User] {
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
        await Datastore.shared.update(for args.id, with: User(args.user))
    }


    func delete(_: Context, args: UserIDArgs) async -> User? {
        await Datastore.shared.delete(for: args.id)
    }

}
```

## Subscriptions

Pioneer has capabilities to handle subscription through websocket, all you need to provide is an `EventStream` that was built with `AsyncSequence`.

```swift
struct Resolver {
    ...

    let (source, supply) = Source<User>.desolate()

    ...

    func create(_: Context, args: AddUserArgs) async -> User {
        let user = await Datastore.shared.insert(User(args.user))
        if user = user {
            supply.tell(with: .next(user))
        }
        return user
    }

    ...

    func update(_: Context, args: UpdateUserArgs) async -> User? {
        let user = await Datastore.shared.update(for args.id, with: User(args.user))
        if user = user {
            supply.tell(with: .next(user))
        }
        return user
    }

    ...

    func onChange(_: Context, _: NoArgs) async -> EventStream<User> {
        source.nozzle()
            .toEventStream()
    }
}
```

!!!warning AsyncSequence and EventStream
Pioneer can only accept `EventStream` built with `AsyncEventStream`, which is an implementation of `EventStream` for any `AsyncSequence`.

Learn why on:

[!ref EventStream](/guides/features/async-event-stream)

!!!

!!!success AsyncStream and Nozzle
Pioneer brings additional `AsyncSequence` for different purposes notably `Nozzle` which in an equivalent ot `AsyncStream` and `Source` which is hot observable version of `Nozzle` that can construct multiple nozzles from a single upstream.

All of these can be easily converted to `EventStream`, and they both will implicit use their own termination callback when the subscription ends.

==- Example code

```swift
// -- Source example --

let (source, supply) = Source<Int>.desolate()

func mutation(...) -> Int {
    let res = ...
    supply.tell(with: .next(res)) // publishing to Source
    return res
}

func subscription(...) -> EventStream<Int> {
    source.nozzle().toEventStream() // easy convertion, automatically use Source deallocating callback when subscription ended
}

// -- AsyncStream example --

func subscription2(...) -> EventStream<Int> {
    let stream = AsyncStream<Int> { con in
        let task = Task {
            for i in 0...100 {
                con.yield(i)
            }
            con.finish()
        }

        con.onTermination = { @Sendable _ in
            task.cancel()
        }
    }
    stream.toEventStream() // use the onTermination callback when subscription ended
}
```

===

!!!

## Relationship

In the part where we declare the User type, we have this `friendIDs` property. This property was there for the base for building a relationship.

You can add a custom resolver by extending the User type with a function that resembles the resolver functions, only here it can access the parent type.

```swift
extension User {
    func friends(_: Context, _: NoArgs) async -> [User] {
        await Datastore.shared.find(with: friendIDs)
    }
}
```

!!!warning N+1 problem
In an actual application where this request is made to database, it's best to avoid directly making a request in a relationship resolver and use a [Dataloader](https://github.com/GraphQLSwift/DataLoader) instead which helps to avoid unnecessary request for fetching the exact same data.

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
    return .init() { keys in
        let promise: EventLoopPromise<User> = req.eventLoop.makePromise(of: User.self)

        promise.completeWithTask {
            let res = await Datastore.shared.find(with: keys)
            return keys.compactMap { key in res.first { $0.id == key } }
        }

        // Map each result to the required enum
        return promise.futureResult.map { users in
            users.map { DataLoaderFutureValue.success($0) }
        }
    }
}

```

DataLoader Async/Await extensions coming soon in later version of Pioneer

+++ Resolver

```swift
extension User {
    func friends(ctx: Context, _: NoArgs, eventLoopGroup: EventLoopGroup) async -> [User] {
        // Get from the DataLoader preventing N+1 problems
        try await ctx.userLoader.loadMany(keys: friendIDs, on: eventLoopGroup).get()
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

[!ref Getting EventLoop](/guides/features/async-await/#getting-eventloop)

===

!!!
