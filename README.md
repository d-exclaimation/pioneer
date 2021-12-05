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

---

```swift
import Vapor
import Pioneer

let app = try Application(.detect())

let server = Pioneer(
    schema: schema(), 
    resolver: Resolver(),
    httpStrategy: .onlyPost,
    websocketProtocol: .graphqlWs,
    introspection: true
)

server.applyMiddleware(on: app)

defer { 
    app.shutdown() 
}

try app.run()
```

---

</details>

---

<details open>
<summary>
	<code>Schema.swift</code>
</summary>

---

```swift
import Graphiti
import Pioneer

func schema() throws -> Schema<Resolver, Request> {
    try .init {
        Scalar(ID.self, as: "ID")
        
        Type(Message.self) {
            Field("id", at: \.id)
            Field("content", at: \.content)
        }

        Query {
            Field("hello", at: Resolver.hello)
        }

        Mutation {
            Field("wave", at: Resolver.wave) {
                Argument("message", at: \.message)
            }
        }

        Subscription {
            SubscriptionField("listen", as: Message.self, atSub: Resolver.listen)
        }        
    }
}
```

---

</details>

---

<details>
<summary>
	<code>Schema.graphql</code>
</summary>

---

```graphql
type Message {
    id: ID!
    content: String!
}

type Query {
    hello: Message!
}

type Mutation {
    wave(message: String!): Message!
}

type Subscription {
    listen: Message!
}

schema {
    query: Query
    mutation: Mutation
    subscription: Subscription
}
```

---

</details>

---

<details open>
<summary>
	<code>Resolver.swift</code>
</summary>

---

```swift
import Pioneer
import Graphiti
import GraphQL
import Desolate

struct Message: Codable {
    var id: ID = .uuid() // <- Using Pioneer built-in ID type for GraphQL's `ID`.
    var content: String 
}

struct Resolver {
    // Desolate package brings a Hot reactive stream similar to Rx's Publisher but use `AsyncSequence` so it can be processed by Pioneer.
    let (jet, actorRef) = Jet<Message>.desolate()
    
    // Using Swift 5.5 async / await in resolver. 
    func hello(_: Void, _: NoArguments) async -> Message { 
        Message(content: "Hello World!")
    }
    
    struct Arg { 
        var message: String 
    }
    
    func wave(_: Void, args: Arg) -> Message {
        let message = Message(content: args.message)
        actorRef.tell(with: .next(message)) // <- Passing a message to an Actor in synchronous code block using Desolate
        return message
    }

    func listen(_: Void, _: NoArgs) -> EventStream<Message> {
        // Pioneer added extension to turn any AsyncSequence into EventStream
        jet.nozzle().toEventStream()
        /// Note:
        ///   Converting Nozzles into EventStream does not need a explicit termination callback,
        ///   but for any other AsyncSequence, provide a termination callback if possible.
        ///
        /// ```swift
        /// MyAsyncSequence(...).toEventStream(
        ///     onTermination: {
        ///         // deallocate resources / stop stream
        ///     }
        /// )
        /// ```
    }
}
```

---

</details>

## Feedback

If you have any feedback, please reach out to us at twitter [@d_exclaimation](https://www.twitter.com/d_exclaimation)
