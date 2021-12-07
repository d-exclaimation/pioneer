<p align="center">
    <img src="./pioneer.png" width="250" />
</p>

<p align="center"> 
    <h1>Pioneer</h1>
</p>

Pioneer is a open-source Swift GraphQL server, for Vapor. Pioneer works with any GraphQL schema built with [Graphiti](https://github.com/GraphQLSwift/Graphiti).

## Getting Started

An overview of GraphQL in general is available in the [README](https://github.com/facebook/graphql/blob/master/README.md) for the [Specification for GraphQL](https://github.com/facebook/graphql). An overview of Graphiti is also described in the package's [README](https://github.com/GraphQLSwift/Graphiti/blob/master/README.md).

### Using Pioneer

Add Graphiti, Vapor and Pioneer to your `Package.swift`:

```swift
import PackageDescription

let package = Package(
    dependencies: [
        .package(url: "https://github.com/GraphQLSwift/Graphiti.git", from: "1.0.0"),
        .package(url: "https://github.com/vapor/vapor.git", from: "4.53.0"),
        .package(url: "https://github.com/d-exclaimation/pioneer", from: "0.1.0")
    ]
)
```

Pioneer provides all the boilerplate and implemention required to run a GraphQL server on top of Vapor that can handle both over HTTP and over Websocket.

#### Declaring entities

Graphiti was designed not to pollute your entity declarations, so declare one should be straight forward.

```swift
import Pioneer

struct Message: Codable {
    var id: ID = .uuid()
    var content: String 
}

```

> 💡  _Here we are using, the `ID` type from Pioneer which is just `String` but unique and not meant to be human readable. The `.uuid()` function will create a new `ID` from an `UUID`. You could have just used the regular initializers_


#### Custom Context type

Graphiti allow usage of custom Context type (with no type pollution) which will pass down to all resolvers. In this case, we will have a authorization token.

```swift
struct Context {
    var token: String?
}
```

> 💡  _Pioneer will ask for a builder function to compute the context from the Vapor `Request` and `Response`. This allow you grab certain value from the request or set new ones to the response_

> ✍️ _Do note that that this context will be compute for each request as it require values that are request specific. If you want to have a shared value, make sure you initialize it outside the builder function_

#### Defining the GraphQL resolver

Resolver are just custom struct used to provide resolver functions to all type of GraphQL operation. Pioneer add features to allow use of `async/await` queries, mutations, and subscriptions on top of Graphiti and Vapor.

```swift
import Graphiti
import Pioneer

struct Resolver {
    let (source, supply) = Source<Message>.desolate()
    
    func hello(_: Context, _: NoArguments) async -> Message { 
        Message(content: "Hello World!")
    }
    
    struct Arg: Decodable { 
        var message: String 
    }
    
    func wave(ctx: Context, args: Arg) async throws -> Message {
        guard token != nil else {
            throw GraphQLErrors(message: "Not authorized")
        }
        let message = Message(content: args.message)
        await supply.task(with: .next(message))
        return message
    }

    func listen(_: Context, _: NoArguments) async -> EventSource<Message> {
        source.eventStream()
    }
}
```

> 💡 _Pioneer will automatically handle all subscription as long as the `EventStream` (or aliased as `EventSource` by Pioneer) built from `AsyncSequence`._

<blockquote>

📚 _Turning any generic `AsyncSequence` into an `EventStream` is as easy as calling `.toEventStream()`; however just like `AsyncStream`, it's good to provide a termination callback to prevent memory leaks when converting_

<details>
<summary><i>Termination callback example</i></summary>

```swift
let stream = MyAsyncSequence<Message>(...)

stream.toEventStream(
    // Require here as it cannot access `AsyncStream.Continuation.onTermination`
    onTermination: {
        // deallocate resources
    }
)
```

</details>
</blockquote>

<blockquote>

💡 _Desolate (exported by Pioneer) provide a handful `AsyncSequence` implementation, which has integration with Pioneer. Due to that, these `AsyncSequence` does not need to explicit termination callback when converted to `EventStream`. `AsyncStream` also have its integration built in._

<details>
<summary>Integration example</summary>

```swift
let nozzle = Nozzle<Message>.single(.init(content: "Hello"))

let eventStream0: EventStream<Message> = nozzle.toEventStream() 

let source = Source<Message>()

let eventStream1: EventStream<Message> = source.eventStream()

let reservoir = Reservoir<String, Message>()

let eventStream2: EventStream<Message> = reservoir.eventStream(for: "some-key")

let stream = AsyncStream<Message> { continuation in 
    // Will use this termination callback, if not specified otherwise
    continuation.onTermination = { @Sendable _ in
        // .. do something
    }
}

let eventStream2: EventStream<Message> = stream.toEventStream()
```

</details>

</blockquote>

#### Describing the schema

It's time to describe the GraphQL schema

```swift
import Graphiti

func schema() throws -> Schema<Resolver, Context> {
    try .init {
        Scalar(ID.self, as: "ID") // <- Using ID as scalar here
        
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
            SubscriptionField("listen", 
                as: Message.self, 
                atSub: Resolver.listen
            )
        } 
    }
}
```

> 💡 _Graphiti takes advantage of Swift's `@resultBuilder` to write GraphQL elegantly in Swift code_

<blockquote>
<details>
<summary>🍇 <i>GraphQL SDL Version</i></summary>

```graphql
type Messsage {
    id: ID!
    content: String!
}

type Query {
    hello: String!
}

type Mutation {
    wave(message: String!): Message!
}

type Subscription {
    listen: Message!
}

schema {
    query: Query,
    mutation: Mutation,
    subscription: Subscription
}
```

</details>
</blockquote>

### Integrating Pioneer, Graphiti, and Vapor

Setting up the server would be fairly straight forward

```swift
import Vapor
import Pioneer

// Create a new Vapor application
let app = try Application(.detect())

// Create a Pioneer server with the schema, resolver, and other configurations
let server = try Pioneer(
    schema: schema(), 
    resolver: Resolver(),
    // Context builder function with Request and Response parameters
    contextBuilder: { req, _ in 
        let token: String? = req.headers["Authorization"]
            .first { $0.contains("Bearer") }
            ?.split(seperator: " ")
            ?.last
            ?.description
        return Context(token: token)
    },
    websocketProtocol: .subscriptionsTransportWs, 
    introspection: true	
)

// Apply Pioneer routing and middlewares to a Vapor application.
server.applyMiddleware(on: app)

defer { 
    app.shutdown() 
}

try app.run()
```

> 💡 Pioneer is built for Vapor and it doesn't require complicated setup to add it a Vapor application

Finally, just ran the server with `swift run` and you should be able to make request to the server.

## Resources

- [Documentation](https://github.com/d-exclaimation/pioneer/blob/main/Sources/Pioneer/Pioneer.swift)

## Feedback

If you have any feedback, please reach out to us at twitter [@d_exclaimation](https://www.twitter.com/d_exclaimation)
