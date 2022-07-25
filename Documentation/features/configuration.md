---
icon: gear
order: 50
---

# Configuration

!!!success Custom Configuration options
From `0.9.3`, Pioneer brought in a structure that will allow easier configuration, which would only require you to pass in the config object into [Pioneer](/references/pioneer) initializer.
!!!

This configuration structure would allow user of the library to create multiple configuration for Pioneer on different environment or situation.

## Config

The Config object takes in all the parameters required to initialized a [Pioneer](/references/pioneer) server instance.

```swift
let server = Pioneer(
    .init(...)
)
```

_You are still allowed to directly passed in the required parameters for [Pioneer](/references/pioneer) into its initializer without the use of configs._

## Built-in configs

Pioneer also brought in custom built-in configuration for different options for a GraphQL server.

### `.default`

A "default" configuration that is _recommended_ for most users

=== Example

```swift
let server = Pioneer(
    .default(
        using: schema,
        resolver: .init(),
        context: { req, res in
            Context(req, res)
        },
        websocketContext: { req, payload, gql in
            Context(req, payload, gql)
        }
    )
)
```

===

==- Configurations

| Name                | Selected                                                    |
| ------------------- | ----------------------------------------------------------- |
| `httpStrategy`      | [!badge variant="primary" text=".queryOnlyGet"]             |
| `websocketProtocol` | [!badge variant="success" text=".graphqlWs"]                |
| `playground`        | [!badge variant="primary" text=".redirect(.apolloSandbox)"] |
| `keepAlive`         | [!badge variant="success" text="12_500_000"]                |

===

### `.secured`

A secured "default" configuration that is also _recommended_ for many users

=== Example

```swift
let server = Pioneer(
    .secured(
        using: schema,
        resolver: .init(),
        context: { req, res in
            Context(req, res)
        },
        websocketContext: { req, payload, gql in
            Context(req, payload, gql)
        }
    )
)
```

===

==- Configurations

| Name                | Selected                                                    |
| ------------------- | ----------------------------------------------------------- |
| `httpStrategy`      | [!badge variant="primary" text=".csrfPrevention"]           |
| `websocketProtocol` | [!badge variant="success" text=".graphqlWs"]                |
| `playground`        | [!badge variant="primary" text=".redirect(.apolloSandbox)"] |
| `keepAlive`         | [!badge variant="success" text="12_500_000"]                |

===

### `.detect`

A configuration that detect from Environment variables

=== Example

```swift
let server = try Pioneer(
    .detect(
        using: schema,
        resolver: .init(),
        context: { req, res in
            Context(req, res)
        },
        websocketContext: { req, payload, gql in
            Context(req, payload, gql)
        }
    )
)
```

===

==- Configurations

| Name                | Environment variables        |
| ------------------- | ---------------------------- |
| `httpStrategy`      | `PIONEER_HTTP_STRATEGY`      |
| `websocketProtocol` | `PIONEER_WEBSOCKET_PROTOCOL` |
| `playground`        | `PIONEER_PLAYGROUND`         |
| `introspection`     | `PIONEER_INTROSPECTION`      |
| `keepAlive`         | `PIONEER_KEEP_ALIVE`         |

<sub> Check [DocC](https://swiftpackageindex.com/d-exclaimation/pioneer/main/documentation/pioneer) for more clarification </sub>

===

### `.httpOnly`

A configuration for a HTTP only GraphQL server

=== Example

```swift
let server = Pioneer(
    .httpOnly(
        using: schema,
        resolver: .init(),
        context: { req, res in
            Context(req, res)
        },
        httpStrategy: .csrfPrevention,
        playground: .graphiql
    )
)
```

===

==- Configurations

| Name                | Selected                                     |
| ------------------- | -------------------------------------------- |
| `websocketProtocol` | [!badge variant="danger" text=".disable"]    |
| `keepAlive`         | [!badge variant="success" text="12_500_000"] |

===

### `.simpleHttpOnly`

A simpler configuration for a HTTP only GraphQL server

=== Example

```swift
let server = Pioneer(
    .simpleHttpOnly(
        using: schema,
        resolver: .init(),
        context: { req, res in
            Context(req, res)
        }
    )
)
```

===

==- Configurations

| Name                | Selected                                        |
| ------------------- | ----------------------------------------------- |
| `httpStrategy`      | [!badge variant="primary" text=".queryOnlyGet"] |
| `websocketProtocol` | [!badge variant="danger" text=".disable"]       |
| `keepAlive`         | [!badge variant="success" text="12_500_000"]    |

===

### `.wsOnly`

A configuration for a WebSocket\* only GraphQL server

_\*Introspection through HTTP is still allowed_

=== Example

```swift
let server = Pioneer(
    .wsOnly(
        using: schema,
        resolver: .init(),
        context: { req, payload, gql in
            Context(req, payload, gql)
        },
        websocketProtocol: .graphqlWs,
        playground: .graphiql
    )
)
```

===

==- Configurations

| Name           | Selected                                     |
| -------------- | -------------------------------------------- |
| `httpStrategy` | [!badge variant="warning" text=".onlyPost"]  |
| `keepAlive`    | [!badge variant="success" text="12_500_000"] |

===

### `.simpleWsOnly`

A simpler configuration for a WebSocket\* only GraphQL server

_\*Introspection through HTTP is still allowed_

=== Example

```swift
let server = Pioneer(
    .simpleWsOnly(
        using: schema,
        resolver: .init(),
        context: { req, payload, gql in
            Context(req, payload, gql)
        }
    )
)
```

===

==- Configurations

| Name                | Selected                                     |
| ------------------- | -------------------------------------------- |
| `httpStrategy`      | [!badge variant="warning" text=".onlyPost"]  |
| `websocketProtocol` | [!badge variant="success" text=".graphqlWs"] |
| `keepAlive`         | [!badge variant="success" text="12_500_000"] |

===
