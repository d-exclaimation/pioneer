<p align="center">
    <img src="./logo.png" width="250" />
</p>

<p align="center"> 
    <h1>Pioneer</h1>
</p>

[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fd-exclaimation%2Fpioneer%2Fbadge%3Ftype%3Dswift-versions&style=for-the-badge)](https://swiftpackageindex.com/d-exclaimation/pioneer)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fd-exclaimation%2Fpioneer%2Fbadge%3Ftype%3Dplatforms&style=for-the-badge)](https://swiftpackageindex.com/d-exclaimation/pioneer)

Pioneer is a open-source Swift GraphQL server, for Vapor. Pioneer works with any GraphQL schema built with [GraphQLSwift/GraphQL](https://github.com/GraphQLSwift/GraphQL) or by libraries that use that package.

## Documentation

- [Documentation Site](https://pioneer-graphql.netlify.app)

## Quick Start

Add Graphiti, Vapor and Pioneer to your `Package.swift`:

```swift
import PackageDescription

let package = Package(
    dependencies: [
        .package(url: "https://github.com/GraphQLSwift/Graphiti.git", from: "1.0.0"),
        .package(url: "https://github.com/vapor/vapor.git", from: "4.54.0"),
        .package(url: "https://github.com/d-exclaimation/pioneer", from: "<latest-version>")
    ],
    targets: [
        .target(
            name: "MyGraphQLServer",
            dependencies: [
                .product(name: "Pioneer", package: "pioneer"),
                .product(name: "Graphiti", package: "Graphiti"),
                .product(name: "Vapor", package: "vapor")
            ]
        )
    ]
)
```

```swift
import Vapor
import Pioneer
import Graphiti

let app = try Application(.detect())

let schema: Schema<Void, Resolver> = ...

let resolver: Resolver = ...

let server = Pioneer(
    schema: schema,
    resolver: resolver,
    websocketProtocol: .graphqlWs
)

server.applyMiddleware(on: app)

defer {
    app.shutdown()
}

try app.run()
```

Pioneer provides all the boilerplate and implemention required to run a GraphQL server on top of Vapor that can handle both over HTTP and over Websocket.

> 💡 Pioneer is built for Vapor, and it doesn't require complicated setup to add it a Vapor application

Finally, just ran the server with `swift run` and you should be able to make request to the server.

## Feedback

If you have any feedback, please reach out at twitter [@d_exclaimation](https://www.twitter.com/d_exclaimation)
