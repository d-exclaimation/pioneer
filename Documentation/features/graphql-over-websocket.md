---
icon: arrow-switch
order: 70
---

# GraphQL Over WebSocket

To perform GraphQL over WebSocket, there need to be a sub protocol to define operations clearly. No "official" sub-protocol nor implementation details on handling subscription given in the GraphQL Spec. However, there are many implementations by the community that have become de facto standards like `subscriptions-transport-ws` and `graphql-ws`.

## Websocket Subprotocol

### graphql-ws

The newer sub-protocol is [graphql-ws](https://github.com/enisdenjo/graphql-ws). Aimed mostly on solving most of the problem with the [subscriptions-transport-ws](#subscriptions-transport-ws).

!!!success GraphQL IDEs :heart: graphql-ws
All major GraphQL IDEs (such as GraphiQL, Apollo Sandbox, BananaCakePop, etc.) has full support for `graphql-ws`.

!!!warning Incompatibilty
The [graphql-playground](https://github.com/graphql/graphql-playground) has been retired and will not support `graphql-ws`. More explaination [here](https://github.com/graphql/graphql-playground/issues/1143).
!!!

#### Usage

You can to use this sub-protocol by specifying when initializing Pioneer.

```swift
let server = Pioneer(
  ...
  websocketProtocol: .graphqlWs
)
```

#### Consideration

Even though the sub-protocol is the recommended and default option, there are still some consideration to take account of. Adoption for this sub-protocol are somewhat limited outside the Node.js / Javascript ecosystem or major GraphQL client libraries.

A good amount of other server implementations on many languages have also yet to support this sub-protocol. So, make sure that libraries and frameworks you are using already have support for [graphql-ws](https://github.com/enisdenjo/graphql-ws). If in doubt, it's best to understand how both sub-protocols work and have options to swap between both options.

### subscriptions-transport-ws

The older standard is [subscriptions-transport-ws](https://github.com/apollographql/subscriptions-transport-ws). This is a sub-protocol from the team at Apollo GraphQL, that was created along side [apollo-server](https://github.com/apollographql/apollo-server) and [apollo-client](https://github.com/apollographql/apollo-client). Some clients and servers still use this to perform operations through websocket especially subscriptions.

!!!warning Legacy
In the GraphQL ecosystem, subscriptions-transport-ws is somewhat considered a legacy protocol. More explaination [here](#consideration).
!!!

#### Usage

By default, Pioneer will already use this sub-protocol to perform GraphQL operations through websocket.

```swift
let server = Pioneer(
  ...
  websocketProtocol: .subscriptionsTransportWs
)
```

#### Consideration

Despite being used by most clients and servers, there are problems with this sub-protocol. Notably, the fact that the package wasn't actively maintained with many issues unresolved and pull request un-reviewed and unmerged, the maintainers themselves also recommend most people to opt for a newer sub-protocol if possible.

Most of the problems (mostly for the implementation) are described in this [issue](https://github.com/enisdenjo/graphql-ws/issues/3) and this [blog post](https://the-guild.dev/blog/graphql-over-websockets).

We also recommend using the newer sub-protocol [graphql-ws](#graphql-ws) when possible unless you have to support a legacy client.

### Disabling

You can also choose to disable GraphQL over WebSocket all together, which you can do by specifiying in the Pioneer initializer.

```swift
let server = Pioneer(
    ...,
    websocketProcotol: .disable
)
```

## Queries and Mutation over Websocket

While the primary operation going through websocket is Subscription, Queries and Mutation can be accepted through websocket and process properly as long as it follows the sub-protocol [above](#websocket-subprotocol).

This also include introspection query.

!!!info Websocket Context
Any operation going through websocket uses the websocket context builder instead of the regular context builder.

[!ref Websocket Context](/guides/advanced/context/#websocket-context)
!!!

## Manual WebSocket Routing

In cases where the routing configuration by Pioneer when using [`.applyMiddleware`](https://swiftpackageindex.com/d-exclaimation/pioneer/documentation/pioneer/pioneer/applymiddleware(on:at:bodystrategy:)) is insufficient to your need, you can opt out and manually set your routes, have Pioneer still handle GraphQL operation, and even execute code on the incoming request before Pioneer handles the GraphQL operation(s).

To do that, you can utilize the newly added [`.webSocketHandler(req:)`](https://swiftpackageindex.com/d-exclaimation/pioneer/documentation/pioneer/pioneer/websockethandler(req:)) method from Pioneer, which will handle incoming `Request`, upgrade to WebSocket, and handle WebSocket messages as well.

!!!success Manual HTTP Routing
Pioneer also provide handler to manually setting routes for HTTP

[!ref Manual HTTP Routing](/features/graphql-over-http/#manual-http-routing)
!!!

!!!warning Upgrade Response
Different from its HTTP counterpart, this handler is only used for upgrading the request not handling each GraphQL operation through WebSocket.

Therefore, this handler can only properly function under **GET** request and is not for intercepting any GraphQL operation(s) going through WebSocket.
!!!

```swift
let app = try Application(.detect())
let server = try Pioneer(...)

app.group("api") {
    app.get("graphql", "subscription") { req async throws in
        // Do something before the upgrade start
        return try await server.webSocketHandler(req: req)
    }
}
```

### Consideration

The [`.webSocketHandler(req:)`](https://swiftpackageindex.com/d-exclaimation/pioneer/documentation/pioneer/pioneer/websockethandler(req:)) method has some behavior to be aware about. Given that it is a method from the Pioneer struct, it still uses the configuration set when creating the Pioneer server, such as:

- It will still use the [WebsocketProtocol](#websocket-subprotocol) and check if the upgrade request is valid / allowed to go through.
  - For example, this handler won't accept **GET** request and perform the upgrade to WebSocket if the provided `Sec-Websocket-Protocol` header value does not match the required value for each websocket subprotocol.
