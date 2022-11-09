---
icon: git-pull-request
order: 10
---

# Migrating to v1

One of the big goal of [v1](/) is to bring fully bring a stable release of Pioneer with all the features and changes added in the past year, and allow Pioneer to be more customisable, and more compatible with more server-side Swift frameworks and libraries.

## Decoupling from Vapor

Pioneer also now no longer a [Vapor](https://github.com/vapor/vapor)-only library and exposes more of its internal functions, structs, protocols, and classes which will allow integrations with other web frameworks.

!!!success
Pioneer [v1](/) will still have first-party integration for [Vapor](https://github.com/vapor/vapor).
!!!

### Middleware

Pioneer will no longer add routes to a [Vapor](https://github.com/vapor/vapor) Application with the `.applyMiddleware` function.

Instead, Pioneer will have a [Vapor](https://github.com/vapor/vapor) integration module that extends [Pioneer](https://swiftpackageindex.com/d-exclaimation/pioneer/documentation/pioneer/pioneer) with [VaporGraphQLMiddleware](https://swiftpackageindex.com/d-exclaimation/pioneer/documentation/pioneer/pioneer/vaporgraphqlmiddleware) which can be use like a regular [Vapor](https://github.com/vapor/vapor) middleware.

+++ v1

```swift #8
let app = try Application(.detect())

let server = Pioneer(
	schema: schema,
	resolver: resolver
)

app.middleware.use(server.vaporMiddleware())
```

+++ v0

```swift #
let app = try Application(.detect())

let server = Pioneer(
	schema: schema,
	resolver: resolver
)

server.applyMiddleware(on: app)
```

+++

### Context Builder

Alongside being a middleware, all context builder and guard functions are passed into the middleware instead of directly to Pioneer. This allow Pioneer be decoupled from Vapor but still allow integration with Vapor's `Request` and `Response` in the context builder.

+++ v1

```swift #8-13
let server = Pioneer(
	schema: schema,
	resolver: resolver
)

app.middleware.use(
	server.vaporMiddleware(
		context: { req, res in
			...
		},
		websocketContext: { req, payload, gql in
			...
		}
	)
)
```

+++ v0

```swift #4-9
let server = Pioneer(
	schema: schema,
	resolver: resolver,
	contextBuilder: { req, res in 
		...
	},
	websocketContextBuilder: { req, params, gql in 
		...
	}
)

server.applyMiddleware(on: app)
```

+++

### WebSocket Guard

Pioneer now properly implement a WebSocket initialisation guard, which will fire for each new GraphQL over WebSocket connection that initialise properly. This allow user configured authorization of each WebSocket connection.

```swift #14-16
let server = Pioneer(
	schema: schema,
	resolver: resolver
)

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

### Same path for all

Pioneer [**v0**](/v0/guides/getting-started/server) uses 3 different paths for GraphQL over HTTP, GraphQL over WebSocket, and GraphQL IDE hosting.

In [**v1**](/), Pioneer will use the same path for all of those, and will instead determine from the request whether is a GraphQL over HTTP request, a GraphQL over WebSocket upgrade request, or a GraphQL IDE request.

## Other changes

### New defaults

Pioneer will now defaults to 
- [.csrfPrevention](https://swiftpackageindex.com/d-exclaimation/pioneer/documentation/pioneer/pioneer/httpstrategy-swift.enum/csrfprevention) for its [HTTPStrategy](/features/graphql-over-http/#http-strategy)
- [.sandbox](https://swiftpackageindex.com/d-exclaimation/pioneer/documentation/pioneer/pioneer/ide/sandbox) for its [WebSocket Protocol](/features/graphql-over-websocket/#websocket-subprotocol)
- `30` seconds for the keep alive interval for GraphQL over WebSocket

### WebSocket callbacks

Some WebSocket callbacks are now exposed as functions in Pioneer. These can be used to add a custom WebSocket layer.

- [.receiveMessage](https://swiftpackageindex.com/d-exclaimation/pioneer/documentation/pioneer/pioneer)
	- Callback to be called for each WebSocket message
- [.initialiseClient](https://swiftpackageindex.com/d-exclaimation/pioneer/documentation/pioneer/pioneer)
	- Callback after getting a GraphQL over WebSocket initialisation message according to the given protocol
- [.executeLongOperation](https://swiftpackageindex.com/d-exclaimation/pioneer/documentation/pioneer/pioneer)
	- Callback to run long running operation using Pioneer
- [.executeShortOperation](https://swiftpackageindex.com/d-exclaimation/pioneer/documentation/pioneer/pioneer)
	- Callback to run short lived operation using Pioneer

### Pioneer capabilities

Some other capabilities of Pioneer is now exposed:

- [.allowed](https://swiftpackageindex.com/d-exclaimation/pioneer/documentation/pioneer/pioneer/allowed(from:allowing:)), Check if a GraphQL request is allowed given the allowed list of operations

- [.csrfVulnerable](https://swiftpackageindex.com/d-exclaimation/pioneer/documentation/pioneer/pioneer/csrfvulnerable(given:)), Check if the headers given show signs of CSRF and XS-Search vulnerability

- [.executeHTTPGraphQLRequest](https://swiftpackageindex.com/d-exclaimation/pioneer/documentation/pioneer/pioneer/csrfvulnerable(given:)), Execute an operation for a given [HTTPGraphQLRequest](https://swiftpackageindex.com/d-exclaimation/pioneer/documentation/pioneer/pioneer/httpgraphqlrequest) and returns  [HTTPGraphQLResponse](https://swiftpackageindex.com/d-exclaimation/pioneer/documentation/pioneer/pioneer/httpgraphqlresponse)

### ConnectionParams to Payload

The type `ConnectionParams` is renamed to `Payload`

```swift #
typealias Payload = [String: Map]?
```

## Brief summary

These are simplified list of things that changed

[!badge variant="success" text="Added or improved"](#tradeoff)
- Vapor integration module
- Vapor GraphQL middleware using Pioneer
- Manually HTTP operation, IDE service, WebSocket upgrade, and WebSocket callbacks
- Manually perform CSRF vulnerability checks and HTTP Strategy check
- Uses 1 path for all types of operations
- Open opportunity for other web framework integrations
- Changed defaults to [.csrfPrevention](https://swiftpackageindex.com/d-exclaimation/pioneer/documentation/pioneer/pioneer/httpstrategy-swift.enum/csrfprevention) for HTTP strategy, [.graphqlWs](https://swiftpackageindex.com/d-exclaimation/pioneer/documentation/pioneer/pioneer/websocketprotocol-swift.enum/graphqlws) for WebSocket protocol, and [.sandbox](https://swiftpackageindex.com/d-exclaimation/pioneer/documentation/pioneer/pioneer/ide/sandbox) for GraphQL IDE.

[!badge variant="danger" text="Removed"](#tradeoff)

- For [Vapor integration](https://github.com/vapor/vapor), must be applied as a middleware at `Application` level (no nesting)
- Removed `Configuration`
