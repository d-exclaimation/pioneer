---
icon: rocket
order: 60
---

# Pioneer

The final step is to integrate Pioneer into the existing Vapor application using the resolver and schema declared before.

## Integration

Adding Pioneer is very simple, construct the instance with the preferred configuration and apply it to any `RouteBuilder`

```swift main.swift
import Vapor

let app = try Application(.detect())

let server = Pioneer(
  schema: schema,
  resolver: Resolver(),
  contextBuilder: { req, res in
      Context(req: req, res: req)
  },
  websocketProtocol: .subscriptionsTransportWs,
  introspection: true,
  playground: true
)

defer {
    app.shutdown()
}

server.applyMiddleware(on: app)

try app.run()
```

Here, we will enable introspection and playground as well as use the `subscriptions-transport-ws` sub-protocol for the WebSocker portion.

Now, just open [http://localhost:8080/playground](http://localhost:8080/playground) to go the GraphQL playground and play with the queries, mutations, and even subscriptions.
