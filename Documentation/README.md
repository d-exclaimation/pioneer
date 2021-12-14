---
icon: home
title: Welcome
---

# Welcome to Pioneer

[Pioneer](https://github.com/d-exclaimation/pioneer) is an easy to use Swift GraphQL :unicorn_face: server implementation built for Vapor that works with any GraphQL schema built with [GraphQLSwift/GraphQL](https://github.com/GraphQLSwift/GraphQL) or using libraries that uses that package.

![Pioneer](pioneer-banner.png)

No complicated setup required to use Pioneer. It is as easy as plugging it into an existing Vapor application.

Pioneer will configure all the necessary things to build a GraphQL API like handling operations through HTTP :incoming_envelope: (**GET** and **POST**), adding GraphQL IDE like [graphql-playground](https://github.com/graphql/graphql-playground), handling subscriptions through WebSocket :dove_of_peace: (using [subscription-transport-ws/graphql-ws](https://github.com/apollographql/subscriptions-transport-ws) and [graphql-ws/graphql-transport-ws](https://github.com/enisdenjo/graphql-ws)).

## Quick Start

You can add Pioneer into an existing Vapor application. Let's say for this instance, we will be using [Graphiti](https://github.com/GraphQLSwift/Graphiti) as GraphQL schema library.

!!! :zap: [Getting Started](./guides/getting-started/setup.md) :zap:
Get up to speed with Pioneer with a full example by checking out the guide.
!!!

[!ref Getting Started](./guides/getting-started/setup.md)

Go to the `main.swift` or any Swift file where you apply your Vapor routing like your `routes.swift` file.

Next, contruct an new Pioneer instance with your flavour of configuration and apply it to any `RoutesBuilder`.

+++ main.swift

```swift
import Vapor
import Pioneer // <- import the package
import Graphiti

let app = try Application(.detect())

let schema: Schema<Void, Resolver> = ... // <- Schema built by Graphiti

let resolver: Resolver = ... // <- Custom resolver struct

let server = Pioneer(
  schema: schema,
  resolver: resolver,
  websocketProtocol: .graphqlWs
)

server.applyMiddleware(on: app) // <- Apply routing to the Application directly

defer {
  app.shutdown()
}

try app.run()
```

+++ routes.swift

```swift
import Vapor
import Pioneer // <- import the package
import Graphiti

let server = Pioneer(...)

func routes(_ app: Application) throws {
  app.get("hello") { req -> String in
    return "Hello, world!"
  }

  server.applyMiddleware(on: app) // <- Apply routing to the Application directly
}

```

+++
