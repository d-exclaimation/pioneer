---
icon: arrow-switch
order: 9
---

# GraphQL Over WebSocket

To perform GraphQL over WebSocket, there need to be a sub protocol to define operations clearly. No "official" sub-protocol nor implementation details on handling subscription given in the GraphQL Spec. However, there are many implementations by the community that have become de facto standards like `subscriptions-transport-ws` and `graphql-ws`.

## Websocket Subprotocol

### graphql-ws

The newer sub-protocol is [graphql-ws](https://github.com/enisdenjo/graphql-ws). Aimed mostly on solving most of the problem with the [subscriptions-transport-ws](#subscriptions-transport-ws).

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

!!!warning
In the GraphQL ecosystem, subscriptions-transport-ws is considered a legacy protocol. More explaination [here](#consideration).
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
