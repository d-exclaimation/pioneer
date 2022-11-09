---
icon: comment-discussion
order: 100
---

# Context

!!!warning 
You're viewing documentation for a previous version of this software. Switch to the [latest stable version](/)
!!!

[GraphQLSwift/GraphQL](https://github.com/GraphQLSwift/GraphQL) allow a custom data structure to be passed into all of your field resolver functions. This allows you to apply some dependency injection to your API and put any code that talks to a database or get the values from the request.

## Context, Request and Response

Pioneer provide a similar solution to `apollo-server-express` for building context using the raw http requests and http responses. It provide both in the context builder that needed to be provided when constructing Pioneer.

!!!success Request specific
This request and response will be request-specific / different for each GraphQL HTTP request.
!!!

```swift main.swift
import Pioneer
import Vapor

let app = try Application(.detect())

@Sendable
func getContext(req: Request, res: Response) -> Context {
    // Do something extra if needed
    Context(req: req, res: req)
}

let server = Pioneer(
    schema: schema,
    resolver: Resolver(),
    contextBuilder: getContext,
    websocketProtocol: .graphqlWs,
    introspection: true,
    playground: .sandbox
)
```

!!!info Websocket Context Builder
From `v0.7.0`, You can now provide a different websocket context builder by passing `websocketContextBuilder`.
[!ref Websocket Context](#websocket-context)
!!!

### Request (HTTP)

The request given is directly from Vapor, so you can use any method you would use in a regular Vapor application to get any values from it.

```swift Getting a cookie example
struct Resolver {
    func someCookie(ctx: Context, _: NoArguments) async -> String {
        return ctx.req.cookies["some-key"]
    }
}
```

### Response

Pioneer already provided the response object in the context builder that is going to be the one used to respond to the request. You don't need return one, and instead just mutate its properties.

!!!warning Returning custom response
There is currently no way for a resolver function to return a custom response. [GraphQLSwift/GraphQL](https://github.com/GraphQLSwift/GraphQL) only take functions that return the type describe in the schema, and Pioneer also have to handle encoding the returned value into a response that follow the proper GraphQL format.
!!!

```swift Setting a cookie example
func users(ctx: Context, _: NoArguments) async -> [User] {
    ctx.response.cookies["refresh-token"] = /* refresh token */
    ctx.response.cookies["access-token"] = /* access token */
    return await getUsers()
}
```

## Websocket Context

Since `0.7.0`, Pioneer allow a seperate context builder for the websocket operations where it provide a different set of arguments.

This context builder is similar to what you can provide to the [`context` property](https://github.com/enisdenjo/graphql-ws/blob/master/docs/interfaces/server.ServerOptions.md#context) in `graphql-ws` where you are given the `Request`, `Payload`, and `GraphQLRequest`.

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
func getWebsocketContext(req: Request, params: Payload, gql: GraphQLRequest) -> {
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
    playground: .sandbox
)
```

!!!success Shared Context Builder
By default if you don't provide a seperate context builder for websocket, Pioneer will try to use the regular `contextBuilder`, by passing a custom request and a dummy response (that serve no value).

==- Custom Request for Websocket
The custom request will similar to the request used to upgrade to websocket but will have:

- The headers taken from `"header"/"headers"` value from the `Payload` or all the entirety of `Payload`
- The query parameters taken from `"query"/"queries"/"queryParams"/"queryParameters"` value from the `Payload`
- The body from the `GraphQLRequest`

!!!warning Only when using shared builder
These addition only apply when using shared context builder. If not, the request will be the exact one from the upgrade request with no custom headers

===
!!!

### Request (WS)

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

### Payload

The connection params is given during websocket initialization from [`payload` as part of `ConnectionInit` message](https://github.com/enisdenjo/graphql-ws/blob/master/PROTOCOL.md#connectioninit) inside an established WebSocket connection.

!!!warning Not strongly typed
Given that the `payload` parameter is custom each client, it does not have any strong typing, so you would have to work with `Map` enum.

==- Pattern matching `Map` enum

```swift
Pioneer(
    ...
    websocketContextBuilder: { req, params, gql in
        let map: Map = params?["some-key"]
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

```swift Getting some values
struct Resolver {
    func someHeader(ctx: Context, _: NoArguments) async -> String? {
        guard .string(let token) = ctx.params?["Authorization"] else { ... }
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

[!ref GraphQLRequest API References](https://swiftpackageindex.com/d-exclaimation/pioneer/documentation/pioneer/graphqlrequest)

## WebSocket Initialisation Hook and Authorization

There might be times where you want to authorize any incoming WebSocket connection before any operation done, and thus before the context builder is executed. 

Since `v0.10.0`, Pioneer now provide a way to run custom code during the GraphQL over WebSocket initialisation phase that can deny a WebSocket connection by throwing an error. 

```swift
let server = Pioneer(
    schema: schema,
    resolver: Resolver(),
    contextBuilder: getContext,
    websocketContextBuilder: getWebsocketContext,
    websocketOnInit: { payload in 
        guard .some(.string(let token)) = payload?["Authorization"] {
            throw Abort(.unauthorized)
        }

        // do something with the Authorization token
    },
    websocketProtocol: .graphqlWs,
    introspection: true,
    playground: .sandbox
)
```