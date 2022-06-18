---
icon: arrow-switch
order: 70
---

# GraphQL Over WebSocket

To perform GraphQL over WebSocket, there need to be a sub protocol to define operations clearly. No "official" sub-protocol nor implementation details on handling subscription given in the GraphQL Spec. However, there are many implementations by the community that have become de facto standards like `subscriptions-transport-ws` and `graphql-ws`.

## Websocket Subprotocol

### graphql-ws

The newer sub-protocol is [graphql-ws](https://github.com/enisdenjo/graphql-ws). Aimed mostly on solving most of the problem with the [subscriptions-transport-ws](#subscriptions-transport-ws).

!!!success GraphiQL :heart: graphql-ws
GraphiQL has full support for `graphql-ws` and Pioneer (since `0.3.0`) can now host GraphiQL with this support (and `subscriptions-transport-ws` support).

!!!warning Incompatibilty
The retired [graphql-playground](https://github.com/graphql/graphql-playground), cloud based IDE such as [Apollo Sandbox](https://studio.apollographql.com/sandbox), some clients and servers has yet to support this protocol. More explaination [here](#consideration).

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

## Websocket Context

Since `0.7.0`, Pioneer allow a seperate context builder for the websocket operations where it provide a different set of arguments. 

This context builder is similar to what you can provide to the [`context` property](https://github.com/enisdenjo/graphql-ws/blob/master/docs/interfaces/server.ServerOptions.md#context) in `graphql-ws` where you are given the `Request`, `ConnectionParams`, and `GraphQLRequest`.


```swift main.swift
import Pioneer
import Vapor

let app = try Application(.detect())

@Sendable 
func getContext(req: Request, res: Response) -> Context {
    try Context(
        req: req, res: res,
        params: nil, 
        gql: req.content.decode(GraphQLRequest.self)
    )
}

@Sendable 
func getWebsocketContext(req: Request, params: ConnectionParams, gql: GraphQLRequest) -> {
    Context(
        req: req, res: .init(),
        params: params, 
        gql: gql
    )
}

let server = Pioneer(
    schema: schema,
    resolver: Resolver(),
    contextBuilder: getContext,
    websocketContextBuilder: getWebsocketContext,
    websocketProtocol: .graphqlWs,
    introspection: true,
    playground: .graphiql
)
```

!!!success Shared Context Builder
By default if you don't provide a seperate context builder for websocket, Pioneer will try to use the regular `contextBuilder`, by passing a custom request and a dummy response (that serve no value).

[!ref Context, Request, Response](/guides/features/graphql-over-http/#context-request-and-response)

==- Custom Request for Websocket
The custom request will similar to the request used to upgrade to websocket but will have:
- The headers taken from `"header"/"headers"` value from the `ConnectionParams`
- The query parameters taken from `"query"/"queries"/"queryParams"/"queryParameters"` value from the `ConnectionParams`
- The body from the `GraphQLRequest`

!!!warning Only when using shared builder
These addition only apply when using shared context builder. If not, the request will be the exact one from the upgrade request with no custom headers

===
!!!


### Request

The request given is directly from Vapor when upgrading to websocket, so you can use any method you would use in a regular Vapor application to get any values from it.

!!!warning Switching Protocol Request
This request object will be the same for each websocket connection and will not change unless the new connection is made. 

It will also not have **any custom headers** and the operation specific graphql query which is different from request given in HTTP.
!!!

```swift Getting Fluent DB or EventLoop
struct Resolver {
    func something(ctx: Context, _: NoArguments) async -> [User] {
        return User.query(on: ctx.req.db).all()
    }
}
```

### ConnectionParams

The connection params is given during websocket initialization from [`payload` as part of `ConnectionInit` message](https://github.com/enisdenjo/graphql-ws/blob/master/PROTOCOL.md#connectioninit) inside an established WebSocket connection. 

!!!warning Not strongly typed
Given that the `payload` parameter is custom each client, it does not have any strong typing, so you would have to work with `Map` enum.

==- Pattern matching `Map` enum

```swift
Pioneer(
    ...
    websocketContextBuilder: { req, params, gql in 
        let map: Map = params?["headers"]
        switch map {
        case .undefined, .null:
            ...
        case .bool(let bool: Bool):
            ...
        case number(let num: Number):
            ...
        case .string(let str: String):
            ...
        case .array(let maps: [Map]):
            ...
        case .dictionary(let dict: OrderedDictionary<String, Map>):
            ...
        }
    }
)
```
===
!!!

```swift Getting header
struct Resolver {
    func someHeader(ctx: Context, _: NoArguments) async -> String? {
        guard .dictionary(let headers) = ctx.params?["headers"] else { ... }
        guard .string(let token) = headers["Authorization"] else { ... }
        return token
    }
}
```

### GraphQLRequest

This is operation specific graphql request / query given an operation is being executed.

```swift Getting operation type
struct Resolver {
    func someHeader(ctx: Context, _: NoArguments) throws -> String? {
        switch try ctx.gql.operationType() {
        case .subscription:
            ...
        case .query:
            ...
        case .mutation:
            ...
        }
    }
}
```

[!ref GraphQLRequest API References](/references/structs/#graphqlrequest)


