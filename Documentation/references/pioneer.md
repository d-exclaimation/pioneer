---
icon: telescope-fill
order: 100
---

# Pioneer

## Pioneer

[Pioneer](#pioneer) GraphQL [Vapor](https://vapor.codes/) Server for handling all GraphQL operations

### `init`

Returns an initialized [Pioneer](#pioneer) server instance.

=== Example

```swift
let server = Pioneer(
    schema: schema,
    resolver: .init(),
    contextBuilder: { req, res in
        Context(req: req, res: res, auth: req.headers[.authorization].first)
    },
    websocketContextBuilder: { req, params, gql in
        let res = Response()
        guard case .dictionary(let headers) = params?["headers"] else {
            return Context(req: req, res: res, auth: nil) 
        }
        guard case .string(let auth) = headers["Authorization"] else {
            return Context(req: req, res: res, auth: nil) 
        }
        Context(req: req, res: res, auth: auth)
    }
)
```

===

==- Options

| Name                | Type                                                         | Description                                                                            |
| ------------------- | ------------------------------------------------------------ | -------------------------------------------------------------------------------------- |
| `schema`            | [!badge variant="primary" text="GraphQLSchema"]              | GraphQL schema used to execute operations                                              |
| `resolver`          | [!badge variant="success" text="Resolver"]                   | Resolver used by the GraphQL schema                                                    |
| `contextBuilder`    | [!badge variant="danger" text="(Request, Response) async throws -> Context"] | Context builder from request (Can be async and can throw an error)     |
| `httpStrategy`      | [!badge variant="primary" text="HTTPStrategy"]               | HTTP strategy <br/> **Default**: `.queryOnlyGet`                                       |
| `websocketContextBuilder`    | [!badge variant="danger" text="(Request, ConnectionParams, GraphQLRequest) async throws -> Context"] | Context builder for the websocket                                      |
| `websocketProtocol` | [!badge variant="primary" text="WebsocketProtocol"]          | Websocket sub-protocol <br/> **Default**: `.subscriptionsTransportws`                  |
| `introspection`     | [!badge variant="primary" text="Bool"]                       | Allowing introspection <br/> **Default**: `true`                                       |
| `playground`        | [!badge variant="primary" text="IDE"]                        | Allowing playground <br/> **Default**: `.graphiql`                                     |
| `keepAlive`         | [!badge variant="warning" text="UInt64?"]                    | Keep alive internal in nanosecond, `nil` for disabling <br/> **Default**: 12.5 seconds |

===


### `init`

**Constraint**:

```swift
where WebsocketContextBuilder == ContextBuilder
```

Returns an initialized [Pioneer](#pioneer) server instance.

=== Example

```swift
let server = Pioneer(
    schema: schema,
    resolver: .init(),
    contextBuilder: { req, res in
        Context(req: req, res: res, auth: req.headers[.authorization].first)
    }
)
```

===

==- Options

| Name                | Type                                                         | Description                                                                            |
| ------------------- | ------------------------------------------------------------ | -------------------------------------------------------------------------------------- |
| `schema`            | [!badge variant="primary" text="GraphQLSchema"]              | GraphQL schema used to execute operations                                              |
| `resolver`          | [!badge variant="success" text="Resolver"]                   | Resolver used by the GraphQL schema                                                    |
| `contextBuilder`    | [!badge variant="danger" text="(Request, Response) async throws -> Context"] | Context builder from request (Can be async and can throw an error)     |
| `httpStrategy`      | [!badge variant="primary" text="HTTPStrategy"]               | HTTP strategy <br/> **Default**: `.queryOnlyGet`                                       |
| `websocketProtocol` | [!badge variant="primary" text="WebsocketProtocol"]          | Websocket sub-protocol <br/> **Default**: `.subscriptionsTransportws`                  |
| `introspection`     | [!badge variant="primary" text="Bool"]                       | Allowing introspection <br/> **Default**: `true`                                       |
| `playground`        | [!badge variant="primary" text="IDE"]                        | Allowing playground <br/> **Default**: `.graphiql`                                     |
| `keepAlive`         | [!badge variant="warning" text="UInt64?"]                    | Keep alive internal in nanosecond, `nil` for disabling <br/> **Default**: 12.5 seconds |

===

### `init` (No context)

**Constraint**:

```swift
where Context == Void
```

Returns an initialized [Pioneer](#pioneer) server instance without explicitly specifying `contextBuilder`.

=== Example

```swift
let server = Pioneer(
    schema: schema,
    resolver: .init()
)
```

===

==- Options

| Name                | Type                                                | Description                                                                            |
| ------------------- | --------------------------------------------------- | -------------------------------------------------------------------------------------- |
| `schema`            | [!badge variant="primary" text="GraphQLSchema"]     | GraphQL schema used to execute operations                                              |
| `resolver`          | [!badge variant="success" text="Resolver"]          | Resolver used by the GraphQL schema                                                    |
| `httpStrategy`      | [!badge variant="primary" text="HTTPStrategy"]      | HTTP strategy <br/> **Default**: `.queryOnlyGet`                                       |
| `websocketProtocol` | [!badge variant="primary" text="WebsocketProtocol"] | Websocket sub-protocol <br/> **Default**: `.subscriptionsTransportws`                  |
| `introspection`     | [!badge variant="primary" text="Bool"]              | Allowing introspection <br/> **Default**: `true`                                       |
| `playground`        | [!badge variant="primary" text="IDE"]               | Allowing playground <br/> **Default**: `.graphiql`                                     |
| `keepAlive`         | [!badge variant="warning" text="UInt64?"]           | Keep alive internal in nanosecond, `nil` for disabling <br/> **Default**: 12.5 seconds |

===


### `init` (Graphiti)

**Constraint**:

```swift
where Schema == Graphiti.Schema<Resolver, Context> and WebsocketContextBuilder == ContextBuilder
```

Returns an initialized [Pioneer](#pioneer) server instance using [Graphiti](https://github.com/GraphQLSwift/Graphiti) schema.

=== Example

```swift
let server = try Pioneer(
    schema: Schema<Resolver, Context>(...),
    resolver: .init(),
    contextBuilder: { req, res in
        Context(req: req, res: res)
    }
)
```

===

==- Options

| Name                | Type                                                         | Description                                                                            |
| ------------------- | ------------------------------------------------------------ | -------------------------------------------------------------------------------------- |
| `schema`            | [!badge variant="warning" text="Schema<Resolver, Context>"]  | Graphiti schema used to execute operations                                             |
| `resolver`          | [!badge variant="success" text="Resolver"]                   | Resolver used by the GraphQL schema                                                    |
| `contextBuilder`    | [!badge variant="danger" text="(Request, Response) async throws -> Void"] | Context builder from request (Can be async and can throw an error)                                                        |
| `httpStrategy`      | [!badge variant="primary" text="HTTPStrategy"]               | HTTP strategy <br/> **Default**: `.queryOnlyGet`                                       |
| `websocketProtocol` | [!badge variant="primary" text="WebsocketProtocol"]          | Websocket sub-protocol <br/> **Default**: `.subscriptionsTransportws`                  |
| `introspection`     | [!badge variant="primary" text="Bool"]                       | Allowing introspection <br/> **Default**: `true`                                       |
| `playground`        | [!badge variant="primary" text="IDE"]                        | Allowing playground <br/> **Default**: `.graphiql`                                     |
| `keepAlive`         | [!badge variant="warning" text="UInt64?"]                    | Keep alive internal in nanosecond, `nil` for disabling <br/> **Default**: 12.5 seconds |

===


### `init` (Graphiti)

**Constraint**:

```swift
where Schema == Graphiti.Schema<Resolver, Context>
```

Returns an initialized [Pioneer](#pioneer) server instance using [Graphiti](https://github.com/GraphQLSwift/Graphiti) schema.

=== Example

```swift
let server = try Pioneer(
    schema: Schema<Resolver, Context>(...),
    resolver: .init(),
    contextBuilder: { req, res in
        Context(req: req, res: res)
    },
    websocketContextBuilder: { req, params, gql in
        let res = Response()
        guard case .dictionary(let headers) = params?["headers"] else {
            return Context(req: req, res: res, auth: nil) 
        }
        guard case .string(let auth) = headers["Authorization"] else {
            return Context(req: req, res: res, auth: nil) 
        }
        Context(req: req, res: res, auth: auth)
    }
)
```

===

==- Options

| Name                | Type                                                         | Description                                                                            |
| ------------------- | ------------------------------------------------------------ | -------------------------------------------------------------------------------------- |
| `schema`            | [!badge variant="warning" text="Schema<Resolver, Context>"]  | Graphiti schema used to execute operations                                             |
| `resolver`          | [!badge variant="success" text="Resolver"]                   | Resolver used by the GraphQL schema                                                    |
| `contextBuilder`    | [!badge variant="danger" text="(Request, Response) async throws -> Void"] | Context builder from request (Can be async and can throw an error)                                                        |
| `httpStrategy`      | [!badge variant="primary" text="HTTPStrategy"]               | HTTP strategy <br/> **Default**: `.queryOnlyGet`                                       |
| `websocketContextBuilder`    | [!badge variant="danger" text="(Request, ConnectionParams, GraphQLRequest) async throws -> Context"] | Context builder for the websocket                                      |
| `websocketProtocol` | [!badge variant="primary" text="WebsocketProtocol"]          | Websocket sub-protocol <br/> **Default**: `.subscriptionsTransportws`                  |
| `introspection`     | [!badge variant="primary" text="Bool"]                       | Allowing introspection <br/> **Default**: `true`                                       |
| `playground`        | [!badge variant="primary" text="IDE"]                        | Allowing playground <br/> **Default**: `.graphiql`                                     |
| `keepAlive`         | [!badge variant="warning" text="UInt64?"]                    | Keep alive internal in nanosecond, `nil` for disabling <br/> **Default**: 12.5 seconds |

===

### `applyMiddleware`

Apply Pioneer GraphQL handlers to a Vapor route

!!!info Route overwrites
Avoid using the same path and methods for:

- **GET** at: `"\(path)"` and `"\(path)/websocket"`
- **POST** at: `"\(path)"`
- **GET** at: `"playground"`

As that will overwrite the applied routing and block certain operations in those endpoints.

It's best to group any other routes or apply the routing after all custom routes.
!!!

=== Example

```swift
server.applyMiddleware(
    on: app,
    at: "graphql"
)
```

===

==- Options

| Name | Type                                            | Description                                |
| ---- | ----------------------------------------------- | ------------------------------------------ |
| `on` | [!badge variant="danger" text="RoutesBuilder"]  | Graphiti schema used to execute operations |
| `at` | [!badge variant="primary" text="PathComponent"] | Resolver used by the GraphQL schema        |

===
