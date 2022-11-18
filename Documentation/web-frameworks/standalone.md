---
icon: cpu
order: 9
---

# Standalone

Pioneer also come with **first-party** integration for a standalone server. This aims to make developing with Pioneer even faster by not having to worry about setting up the server.

!!!success
Under the hood, the standalone server uses the [Vapor](/web-frameworks/vapor) integration.
!!!

```swift #11
import Pioneer

let server = Pioneer(
    schema: schema,
    resolver: Resolver(),
    websocketProtocol: .graphqlWs,
    introspection: true,
    playground: .sandbox
)

try server.standaloneServer()
```

## Configuration

The standalone server allow some configuration to be better suited for your use case and environment.

### Port, Host, and Env

The [.standaloneServer](https://swiftpackageindex.com/d-exclaimation/pioneer/documentation/pioneer/pioneer) function can take specified:
=== Port number (`port`)
- Must be a valid port number and an `Integer`
- Defaults to `4000`

```swift #2
try server.standaloneServer(
    port: 8080
)
```
===
=== Hostname (`host`)
- Must be a `String` containing either an IP address or `"localhost"`
- Defaults to `127.0.0.1`

```swift #2
try server.standaloneServer(
    host: "0.0.0.0"
)
```
===
=== Environment mode (`env`)
- Must be either `"development"`, `"testing"`, `"production"`, `"dev"`, `"prod"`, or `"test"`.

```swift #2
try server.standaloneServer(
    env: "production"
)
```

<small><a href="https://docs.vapor.codes/basics/environment/#changing-environment">More info on environment mode</a></small>
===

### CORS

Given that the standalone option is responsible setup the server, any middleware need to be configured by the function. 

To allow CORS using a middleware, [.standaloneServer](https://swiftpackageindex.com/d-exclaimation/pioneer/documentation/pioneer/pioneer) function can take specified [CORSMiddleware.Configuration](https://docs.vapor.codes/advanced/middleware/?h=cors#cors-middleware).

```swift #5-9
try server.standaloneServer(
    port: 443,
    host: "0.0.0.0",
    env: "production",
    cors: .init(
        allowedOrigin: .all,
        allowedMethods: [.GET, .POST, .OPTIONS],
        allowedHeaders: [.accept, .authorization, .contentType, .origin, .xRequestedWith, .userAgent, .accessControlAllowOrigin]
    )  
)
```

## Context

Configuring context with the standalone server is identical with the [Vapor](/web-frameworks/vapor) integration.

[!ref Context](/web-frameworks/vapor#context)