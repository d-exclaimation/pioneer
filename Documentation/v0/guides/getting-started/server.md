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
        Context(req: req, res: res)
    },
    websocketContextBuilder { req, params, gql in 
        Context(req: req, res: .init())
    },
    websocketProtocol: .graphqlWs,
    introspection: true,
    playground: .sandbox
)

defer {
    app.shutdown()
}

server.applyMiddleware(on: app)

try app.run()
```

Here, we will enable introspection and Apollo Sandbox for the playground as well as use the `graphql-ws` sub-protocol for GraphQL over WebSocket.

Now, just open [http://localhost:8080/playground](http://localhost:8080/playground) to go the Apollo Sandbox and play with the queries, mutations, and even subscriptions.

!!!success You're set
You've just created your Swift GraphQL API with Pioneer
!!!
