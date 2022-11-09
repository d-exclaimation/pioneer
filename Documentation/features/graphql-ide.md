---
icon: squirrel
order: 8
---

# GraphQL IDE

GraphQL IDEs are quick and convenient ways to develop and test your GraphQL APIs, by making request on it without having to worry about setting up all the proper HTTP method, headers, and body.

Pioneer with any *web framework integrations*\* such as the [Vapor](https://github.com/vapor/vapor) will be able to host GraphQL IDE on the same path used for all other operations. 

<small>*As long as the web framework integrations are created properly</small>

!!!info
Pioneer will disable any GraphQL IDE automatically regardless of the specified parameter, if introspection is disabled, as GraphQL IDE relies on introspection to provide syntax highlighting.
!!!

## Apollo Sandbox

Apollo Sandbox is in browser GraphQL IDE developed by Apollo GraphQL and their choice of replacement for [GraphQL Playground](#graphql-playground). Apollo Sandbox provide all features available in [GraphQL Playground](#graphql-playground) and a lot more. 

![](/static/sandbox.png)

Embedded version of Apollo Sandbox served similarly to [GraphiQL](#graphiql) without needing to setup CORS.

```swift #3
let server = Pioneer(
    ...,
    playground: .sandbox
)
```

==- Cloud Redirect 

!!!warning
CORS need to be configured for the specific web framework used with Pioneer.
!!!


```swift #3
let server = Pioneer(
    ...,
    playground: .redirect(to: .apolloSandbox)
)
```

<sub>You can also just set this up on your own</sub>

===


## GraphiQL

GraphiQL is the official GraphQL IDE by the GraphQL Foundation. The current GraphiQL version has met feature parity with [GraphQL Playground](#graphql-playground).

![](/static/graphiql.png)


```swift #3
let server = Pioneer(
    ...,
    playground: .graphiql
)
```

## GraphQL Playground

The most common GraphQL IDE is graphql-playground which is a variant of the original GraphiQL with some added improvement, both UI and certain functionalities.

!!!warning
The [GraphQL Playground](#graphql-playground) project has been [retired](https://github.com/graphql/graphql-playground/issues/1143). Pioneer will still have this option. However, it recommended to use something else as we don't recommend long-term use of this unmaintained project.
!!!

![](/static/playground.png)


```swift #3
let server = Pioneer(
    ...,
    playground: .playground
)

```

## Banana Cake Pop

Banana Cake Pop is both a cloud hosted in browser and a downloable application GraphQL IDE developed by people over at [ChilliCream](https://chillicream.com/). Banana Cake Pop provide all features available in [GraphQL Playground](#graphql-playground) and a few more. However when using the cloud based solution, you required to specify a CORS configuration similar to [Apollo Sandbox](#apollo-sandbox).

![](/static/bananacakepop.png)

!!!warning
CORS need to be configured for the specific web framework used with Pioneer.
!!!


```swift #3
let server = Pioneer(
    ...,
    playground: .redirect(to: .bananaCakePop)
)
```

<sub>You can also just set this up on your own</sub>
