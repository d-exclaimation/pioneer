---
icon: arrow-switch
order: 70
---

# GraphQL Over WebSocket

To perform GraphQL over Websockets, there need to be a sub protocol to define operations clearly. No "official" sub protocol nor implementation details on handling subscription given in the GraphQL Spec. However, there are many implementations by the community that have become de facto standards like `subscriptions-transport-ws` and `graphql-ws`.

## subscriptions-transport-ws

The current standard is [subscriptions-transport-ws](https://github.com/apollographql/subscriptions-transport-ws). This is a sub-protocol from the team at Apollo GraphQL, that was created along side [apollo-server](https://github.com/apollographql/apollo-server) and [apollo-client](https://github.com/apollographql/apollo-client). Most clients and servers still use this to perform operations through websocket especially subscriptions.

### Usage

By default, Pioneer will already use this sub-protocol to perform GraphQL operations through websocket.

```swift
let server = Pioneer(
  ...
  websocketProtocol: .subscriptionsTransportWs
)
```

### Consideration

Despite being used by most clients and servers, there are problems with this sub-protocol. Notably, the fact that the package wasn't actively maintained with many issues unresolved and pull request un-reviewed and unmerged, the maintainers themselves also recommend most people to opt for a newer sub-protocol if possible.

Most of the problems (mostly the implementation) are described in this [issue](https://github.com/enisdenjo/graphql-ws/issues/3) and [blog post](https://the-guild.dev/blog/graphql-over-websockets).

We also recommend using the newer sub-protocol [graphql-ws](#graphql-ws) when possible. However, [subscriptions-transport-ws](#subscriptions-transport-ws) will stay as the default sub protocol until most clients on all major platforms supported the newer sub protocol.

## graphql-ws

The newer sub-protocol is [graphql-ws](https://github.com/enisdenjo/graphql-ws). Aimed mostly on solving most of the problem with the [subscriptions-transport-ws](#subscriptions-transport-ws).

!!!warning GraphQL IDE Incompatibilty
Currently, most GraphQL IDE like [graphql-playground](https://github.com/graphql/graphql-playground) and something like [Apollo Sandbox](https://studio.apollographql.com/sandbox) doesn't not support this protocol.
!!!

### Usage

You can to use this sub-protocol by specifying when initializing Pioneer.

```swift
let server = Pioneer(
  ...
  websocketProtocol: .graphqlWs
)
```

### Consideration

Even though the sub-protocol is the recommended option, there are still some consideration to take account of. Adoption for this sub-protocol are somewhat limited outside the Node.js / Javascript ecosystem.

Here are some notable clients and tools that has yet to support [graphql-ws](https://github.com/enisdenjo/graphql-ws) as of 2021:

- [apollo-ios](https://github.com/apollographql/apollo-ios), already an [issue](https://github.com/apollographql/apollo-ios/issues/1622) but not yet resolved.
- [graphql-kotlin](https://github.com/ExpediaGroup/graphql-kotlin), no issue mentioning the new protocol yet.
- [graphql-flutter](https://github.com/zino-app/graphql-flutter), already an [issue](https://github.com/zino-app/graphql-flutter/issues/958) but not yet resolved.
- [gql (python)](https://github.com/graphql-python/gql/), already an [issue](https://github.com/graphql-python/gql/issues/240) but not yet resolved.
- [Apollo Sandbox](https://www.apollographql.com/docs/studio/explorer/).

A good amount of other server implementations on many languages have also yet to support this sub-protocol. So, make sure that libraries and frameworks you are using already have support for [graphql-ws](https://github.com/enisdenjo/graphql-ws). If in doubt, it's best to understand how both sub-protocols work and have options to swap between both options.

## Disabling

You can also choose to disable GraphQL over WebSocket all together, which you can do by specifiying in the Pioneer initializer.

```swift
let server = Pioneer(
    ...,
    websocketProcotol: .disable
)
```
