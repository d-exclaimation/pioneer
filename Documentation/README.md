---
icon: home
title: Welcome
---

# Welcome to Pioneer

[Pioneer](https://github.com/d-exclaimation/pioneer) is a simple GraphQL :unicorn_face: server built for Swift and Vapor that works with any GraphQL schema built with [GraphQLSwift/GraphQL](https://github.com/GraphQLSwift/GraphQL).

![Pioneer](pioneer-banner.png)

No complicated setup required to use Pioneer. It is as easy as plugging it into an existing Vapor application (it might even looked familiar).

Pioneer will configure all the necessary things to build a GraphQL API such as:

- Handling operations through HTTP :incoming_envelope: (**GET** and **POST**).
- Adding GraphQL IDE like [GraphiQL](https://github.com/graphql/graphiql) with subscriptions support.
- Handling subscriptions through WebSocket :dove_of_peace:

## Quick Start

You can add Pioneer into any existing Vapor application with any GraphQL schema library made from [GraphQLSwift/GraphQL](https://github.com/GraphQLSwift/GraphQL) like [Graphiti](https://github.com/GraphQLSwift/Graphiti).

[!ref Getting Started](./guides/getting-started/setup.md)

Add this line to add Pioneer as one of your dependencies.

```swift
.package(url: "https://github.com/d-exclaimation/pioneer", from: "0.9.3")
```

Go to the `main.swift` or any Swift file where you apply your Vapor routing like your `routes.swift` file.

Next, contruct an new Pioneer instance with your flavour of configuration and apply it to any `RoutesBuilder`.

+++ Barebone Setup

```swift main.swift
import Vapor
import Pioneer
import Graphiti

let app = try Application(.detect())

let server = Pioneer(
    schema: Schema<Void, Resolver> {
        ...
    },
    resolver: Resolver(),
    websocketProtocol: .graphqlWs
)

server.applyMiddleware(on: app) // <- Apply routing to the Application directly

defer {
    app.shutdown()
}

try app.run()
```

+++ Vapor template setup

```swift routes.swift
import Vapor
import Pioneer
import Graphiti

let server = Pioneer(
    schema: Schema<Void, Resolver> {
        ...
    },
    resolver: Resolver(),
    websocketProtocol: .graphqlWs
)

func routes(_ app: Application) throws {
    app.get("hello") { req -> String in
        return "Hello, world!"
    }

    server.applyMiddleware(on: app) // <- Apply routing to the Application directly
}

```

+++
