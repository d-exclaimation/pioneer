<p align="center">
    <img src="./pioneer.png" width="250" />
</p>

<p align="center"> 
    <h1>Pioneer</h1>
</p>

Feature rich, easy to use, spec-compliant Swift GraphQL server.

## Resources

- [Documentation](https://github.com/d-exclaimation/pioneer/blob/main/Sources/Pioneer/Pioneer.swift)


## Usage/Examples

```swift
import Vapor
import Graphiti
import Pioneer

struct Resolver {
    func hello() -> String { 
        "Hello World!" 
    }
}

let resolver = Resolver()

let schema = try Schema<Resolver, Request> {
    Query {
        Field("hello", at: Resolver.hello)
    }
}

let app = try Application(.detect())

let server = Pioneer(
    schema: schema, 
    resolver: resolver
)

server.applyMiddleware(
    on: app, 
    at: "graphql"
)

defer { 
    app.shutdown() 
}

try app.run()
```



## Feedback

If you have any feedback, please reach out to us at twitter [@d_exclaimation](https://www.twitter.com/d_exclaimation)
