---
icon: globe
order: 10
---

# Vapor

Pioneer will have a built-in **first-party** integration with [Vapor](https://github.com/vapor/vapor). This aims to make developing with Pioneer faster by not having to worry about creating integrations for the most common option for a web framework in Swift.

This integration added a couple additional benefits.

```swift #15
import Pioneer
import Vapor

let app = try Application(.detect())

let server = Pioneer(
    schema: schema,
    resolver: Resolver(),
    websocketProtocol: .graphqlWs,
    introspection: true,
    playground: .sandbox
)

app.middleware.use(
    server.vaporMiddleware()
)
```

## Context

### HTTP-based Context

Pioneer provide a similar solution to `@apollo/server/express4` for building context using the raw HTTP requests and responses. It provide both in the context builder that needed to be provided when create the middleware.

!!!success
This request and response will be request-specific / different for each GraphQL HTTP request.
!!!

```swift #16-18
import Pioneer
import Vapor

let app = try Application(.detect())

let server = Pioneer(
    schema: schema,
    resolver: Resolver(),
    websocketProtocol: .graphqlWs,
    introspection: true,
    playground: .sandbox
)

app.middleware.use(
    server.vaporMiddleware(
        context: { (req: Request, res: Response) in
            ...
        }
    )
)
```

#### Request (HTTP)

The request given is directly from [Vapor](https://github.com/vapor/vapor), so you can use any method you would use in a regular [Vapor](https://github.com/vapor/vapor) application to get any values from it.

```swift #2 Getting a cookie example
func someCookie(ctx: Context, _: NoArguments) async -> String {
    return ctx.req.cookies["some-key"]
}
```

#### Response

The response object is already provided in the context builder that is going to be the one used to respond to the request. 

!!!
You don't need return one, and instead just mutate its properties.
!!!

```swift #2-3 Setting a cookie example
func users(ctx: Context, _: NoArguments) async -> [User] {
    ctx.response.cookies["refresh-token"] = /* refresh token */
    ctx.response.cookies["access-token"] = /* access token */
    return await getUsers()
}
```

### Websocket-based Context

[Vapor](https://github.com/vapor/vapor) integration also allow seperate context builder which is similar to what you can provide to the [`context`](https://github.com/enisdenjo/graphql-ws/blob/master/docs/interfaces/server.ServerOptions.md#context) property in [graphql-ws](https://github.com/enisdenjo/graphql-ws) where you are given the [Request](#request-ws), [Payload](#payload), and [GraphQLRequest](#graphqlrequest).

!!!success
WebSocket context builder is **optional**. 

Pioneer's [Vapor](https://github.com/vapor/vapor) integration will try to use the HTTP context builder for WebSocket by providing all the relevant information into the [Request](#request-ws).
!!!

```swift #19-21
import Pioneer
import Vapor

let app = try Application(.detect())

let server = Pioneer(
    schema: schema,
    resolver: Resolver(),
    websocketProtocol: .graphqlWs,
    introspection: true,
    playground: .sandbox
)

app.middleware.use(
    server.vaporMiddleware(
        context: { (req: Request, res: Response) in
            ...
        },
        websocketContext: { (req: Request, payload: Payload, gql: GraphQLRequest) in
            ...
        }
    )
)
```


#### Request (WS)

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


==- Changes to [Request](#request-ws) for shared context builder
!!!info
This is only for using 1 shared context builder, and not providing a separate WebSocket context builder.
!!!
The custom request will similar to the request used to upgrade to websocket but will have:

- The headers taken from `"header"/"headers"` value from the `Payload` or all the entirety of [Payload](#payload)
- The query parameters taken from `"query"/"queries"/"queryParams"/"queryParameters"` value from the [Payload](#payload)
- The body from the [GraphQLRequest](#graphqlrequest)

===

#### Payload

The connection params is given during websocket initialization from [`payload` as part of `ConnectionInit` message](https://github.com/enisdenjo/graphql-ws/blob/master/PROTOCOL.md#connectioninit) inside an established WebSocket connection.

!!!warning
Given that the `payload` parameter is custom each client, it does not have any strong typing, so you would have to work with `Map` enum.
!!!

```swift #2-3 Getting some values
func someHeader(ctx: Context, _: NoArguments) async -> String? {
    guard .string(let token) = ctx.params?["Authorization"] else { ... }
    return token
}
```

#### GraphQLRequest

This is operation specific graphql request / query given an operation is being executed.

```swift #2-9 Getting operation type
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
```

### WebSocket Guard

There might be times where you want to authorize any incoming WebSocket connection before any operation done, and thus before the context builder is executed. 

Pioneer's [Vapor](https://github.com/vapor/vapor) integration provide a way to run custom code during the GraphQL over WebSocket initialisation phase that can deny a WebSocket connection by throwing an error. 

```swift #9-11
app.middleware.use(
	server.vaporMiddleware(
		context: { req, res in
			...
		},
		websocketContext: { req, payload, gql in
			...
		},
		websocketGuard: { req, payload in 
			...
		}
	)
)
```

## Handlers

Pioneer's [Vapor](https://github.com/vapor/vapor) also exposes the HTTP handlers for GraphQL over HTTP operations, GraphQL over WebSocket upgrade, and GraphQL IDE hosting.

This allow opting out of the middleware for integrating Pioneer and [Vapor](https://github.com/vapor/vapor), by manually setting this handlers on routes.

### GraphQL IDE hosting

[.ideHandler](https://swiftpackageindex.com/d-exclaimation/pioneer/documentation/pioneer/pioneer) will serve incoming request with the configured [GraphQL IDE](/features/graphql-ide).

```swift #3
app.group("graphql") { group in
    group.get { req in
        server.ideHandler(req: req)
    }
}
```


### GraphQL over HTTP operations

[.httpHandler](https://swiftpackageindex.com/d-exclaimation/pioneer/documentation/pioneer/pioneer) will execute a GraphQL operation and return a well-formatted response.

```swift #3-8
app.group("graphql") { group in
    group.post { req in
        try await server.httpHandler(
            req: req, 
            context: { req, res in 
                ...
            }
        )
    }
}
```

### GraphQL over WebSocket upgrade

[.webSocketHandler](https://swiftpackageindex.com/d-exclaimation/pioneer/documentation/pioneer/pioneer) will upgrade incoming request into a WebSocket connection and start the process of GraphQL over Websocket.

```swift #3-11
app.group("graphql") { group in
    group.get("ws") { req in
        try await server.webSocketHandler(
            req: req,
            context: { req, payload, gql in
                ...
            },
            guard: { req, payload in
                ...
            }
        )
    }
}
```

## Additional benefits


The [Vapor](https://github.com/vapor/vapor) integration include other benefits such as:

- Includes all security measurements done by Pioneer automatically (i.e. [CSRF Prevention](/features/graphql-over-http#csrf-and-xs-search))
- Automatically operation check for HTTP methods using the given [HTTPStrategy](/features/graphql-over-http/#http-strategy)
- Extensions for `CORSMiddleware.Configuration` for allowing Cloud based [GraphQL IDE](/features/graphql-ide)s
