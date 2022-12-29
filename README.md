<p align="center">
    <img src="./Documentation/public/pioneer-banner.png"/>
</p>

[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fd-exclaimation%2Fpioneer%2Fbadge%3Ftype%3Dswift-versions&style=flat-square)](https://swiftpackageindex.com/d-exclaimation/pioneer)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fd-exclaimation%2Fpioneer%2Fbadge%3Ftype%3Dplatforms&style=flat-square)](https://swiftpackageindex.com/d-exclaimation/pioneer)
[![Build Status](https://img.shields.io/endpoint.svg?url=https%3A%2F%2Factions-badge.atrox.dev%2Fd-exclaimation%2Fpioneer%2Fbadge%3Fref%3Dmain&style=flat-square)](https://actions-badge.atrox.dev/d-exclaimation/pioneer/goto?ref=main)

Pioneer is an open-source, [spec-compliant](https://github.com/graphql/graphql-http#servers) GraphQL server that's compatible with any GraphQL schema built with [GraphQLSwift/GraphQL](https://github.com/GraphQLSwift/GraphQL). 

## Setup

```swift
.package(url: "https://github.com/d-exclaimation/pioneer", from: "1.0.0")
```

### Quick start

```swift
import Graphiti
import Pioneer

struct Resolver { ... }

let schema = try Schema<Resolver, Void> { ... }

let server = Pioneer(
    schema: schema,
    resolver: .init()
)

try server.standaloneServer(
    port: 4000,
    host: "127.0.0.1"
)
```

## Usage/Examples

- [Documentation](https://pioneer.dexclaimation.com/docs)
- [Getting started](https://pioneer.dexclaimation.com/docs/getting-started)
- [API References](https://swiftpackageindex.com/d-exclaimation/pioneer/documentation)
- [Example](https://github.com/d-exclaimation/pioneer-example)

## Feedback

If you have any feedback, feel free open an issue or discuss it in the discussion tab.

### Attribution

This project is heavily inspired by [Apollo Server](https://github.com/apollographql/apollo-server), and it would not have been possible without the work put into [GraphQLSwift/GraphQL](https://github.com/GraphQLSwift/GraphQL).
