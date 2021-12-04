<p align="center">
    <img src="./pioneer.png" width="250" />
</p>

<p align="center"> 
    <h1>Pioneer</h1>
</p>

Spec-compliant Swift GraphQL server for Vapor.

## Features

- Handle GraphQL execution (synchronous and asynchronous) both on `GET` and `POST` HTTP request.
- Handle GraphQL subscription through WebSocket.
- Handle `Vapor` routing for all types of operations.
- Handle introspection blocking, HTTP strategies, and WebSocket sub-protocols such as  `subscriptions-transport-ws/graphql-ws` or `graphql-ws/graphql-transport-ws`.
- Provide API for `AsyncSequence` to be used as `EventStream`.
- Provide API for `async/await` resolvers.

### Limitations

- Require Swift 5.5, precisely the new `Concurrency`.
- Can only handle subscription `EventStream` built with `AsyncSequence`.

## Resources

- [Documentation](https://github.com/d-exclaimation/pioneer/blob/main/Sources/Pioneer/Pioneer.swift)


## Usage/Examples

<details open>
<summary>
	<code>main.swift</code>
</summary>

```swift
import Vapor
import Pioneer

let resolver = Resolver()

let app = try Application(.detect())

let server = Pioneer(
    schema: schema, 
    resolver: resolver
)

server.applyMiddleware(on: app)

defer { 
    app.shutdown() 
}

try app.run()
```

</details>
<br/>
<details open>
<summary>
	<code>Schema.swift</code>
</summary>

```swift
import Graphiti

let schema = try Schema<Resolver, Request> {
    Query {
        Field("hello", at: Resolver.hello)
    }
    
    Mutation {
        Field("wave", at: Resolver.wave) {
            Argument("message", at: \.message)
        }
    }
    
    Subscription {
        SubscriptionField("listen", as: String.self, atSub: Resolver.listen)
    }
}
```

</details>
<br/>
<details>
<summary>
	<code>Schema.graphql</code>
</summary>

```graphql
type Query {
    hello: String!
}

type Mutation {
    wave(message: String!): String!
}

type Subscription {
    listen: String!
}

schema {
    query: Query
    mutation: Mutation
    subscription: Subscription
}
```

</details>
<br/>
<details>
<summary>
	<code>Resolver.swift</code>
</summary>

```swift
import Graphiti
import GraphQL
import Desolate

struct Resolver {
    let (jet, actorRef) = Jet<String>.desolate()
    
    func hello(_: Void, _: NoArguments) async -> String { 
        "Hello World!" 
    }
    
    struct Arg { 
        var message: String 
    }
    
    func wave(_: Void, args: Arg) -> String {
        actorRef.tell(with: .next(args.message))
        return args.message
    }
    
    func listen(_: Void, _: NoArguments) -> EventStream<String> {
        jet.eventStream()
    }
}
```

</details>

## Feedback

If you have any feedback, please reach out to us at twitter [@d_exclaimation](https://www.twitter.com/d_exclaimation)
