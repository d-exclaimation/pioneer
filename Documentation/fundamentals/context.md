---
icon: comment-discussion
order: 10
---

# Context

[GraphQLSwift/GraphQL](https://github.com/GraphQLSwift/GraphQL) allow a custom data structure to be passed into all of your field resolver functions. 

The context can be in any form, but it is useful for:
- Dependencies injection to each resolver function in the schema
- Providing or deriving an operation specific value

## Operation specific contextual value

As for example, your schema resolve prices of coffee for your users which could have subscribed to a membership plan with different benefits and discount for each price of a coffee.

```swift #2
func price(ctx: Any?, args: AmountArgs) async -> Int {
    let discount = // What to put here, how to figure out membership
    return price * args.amount
}
```

One approach is to add this value within the arguments, but that comes with issues of security and that fact that this value has to be explicitly given.

### Context for derived values

The context value can be used to provide additional values specific to the request that are derived outside the GraphQL request.

```swift #2
struct Context {
    var user: User?
}
```

### Using context from resolver

This context struct can be in any form and include any values that may come in useful to be derived outside of the GraphQL request. For this example, it will contain the user who are performing the query.

```swift #2-11
func price(ctx: Context, args: AmountArgs) async -> Int {
    guard let membership = ctx.user?.membership else {
        return price * args.amount   
    }
    switch membership {
        case .silver(let years):
            return price * min(0.75, 1 - (years / 10)) * args.amount
        case .gold(let years):
            return price * min(0.60, 1 - (years / 10))) * args.amount
        case .platinum:
            return price * 0.5 * args.amount
    }
}
```

## Dependencies injection

Another use case for context is to perform dependency injection to all resolvers.

As an example, you have created a [PubSub](https://swiftpackageindex.com/d-exclaimation/pioneer/documentation/pioneer/pubsub) implementation that uses Redis, which required to be initialised on `main.swift`.

```swift #8-10 main.swift
import Vapor
import Pioneer

let app = Application(...)

let server = Pioneer(...)

let pubsub: PubSub = MyPubSub(app.redis)

pubsub.start()
```

### Context for dependencies

Passing down this to each one the resolver would require dependency injection, which can be done through Context.

```swift #2
struct Context {
    var pubsub: PubSub
}
```

==- Passing down through a context builder for [Vapor](https://github.com/vapor/vapor)

!!!info
This is just an example passing down when using [Vapor](https://github.com/vapor/vapor). Context are not tied to [Vapor](https://github.com/vapor/vapor).
!!!

```swift #
import Vapor
import Pioneer

let app = Application(...)

let server = Pioneer(...)

let pubsub: PubSub = MyPubSub(app.redis)

pubsub.start()

app.middleware.use(
    server.vaporMiddleware(
        context: { _, _ in
            Context(pubsub: pubsub)
        }
    )
)
```

===

### Using dependencies from resolver

All of the resolvers would have access to this context and can get the `pubsub` property from it and use it.

```swift #
func onOrder(ctx: Context, args: NoArguments) -> EventStream<Order> {
    ctx.pubsub.asyncStream(Order.self, for: "*:order").toEventStream()
}
```