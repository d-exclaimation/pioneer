---
icon: squirrel
order: 60
---

# GraphQL IDE

GraphQL IDEs are quick and convenient ways to develop and test your GraphQL APIs, by making request on it without having to worry about setting up all the proper HTTP method, headers, and body.

## GraphQL Playground

The most common GraphQL IDE is graphql-playground which is a variant of the original GraphiQL with some added improvement, both UI and functionalities.

![](/static/playground.png)

[GraphQL Playground](#graphql-playground) is self-hosted in-browser version. Pioneer can host a [GraphQL Playground](#graphql-playground) at the `/playground` endpoint by specifying it in the initialzer.

!!! Introspection
Pioneer will disable [GraphQL Playground](#graphql-playground) automatically regardless of the specified boolean parameter, if introspection is disabled, as [GraphQL Playground](#graphql-playground) relies on introspection to provide syntax highlighting.
!!!

```swift
let server = Pioneer(
    ...,
    httpStrategy: .both,
    playground: true
)

app.group("api") { group in
    server.applyMiddleware(on: group)
}
```

This will result in

```http
GET /api/graphql
POST /api/graphql
WS /api/graphql/websocket

GET /api/playground # (For playground)
```

!!!warning Retired
The [GraphQL Playground](#graphql-playground) project has been [retired](https://github.com/graphql/graphql-playground/issues/1143). Pioneer will still have this option since this is still the most featured in browser self-hosted GraphQL IDE. However, it recommended to use something else as we don't recommend long-term use of this unmaintained project.
!!!

## Apollo Sandbox

Apollo Sandbox is a cloud hosted in browser GraphQL IDE developed by Apollo GraphQL and their choice of replacement for [GraphQL Playground](#graphql-playground). Apollo Sandbox provide all features available in [GraphQL Playground](#graphql-playground) and more. However, this is a cloud based solution that require CORS configuration, cannot be self-hosted, and is not open source.

![](/static/sandbox.jpeg)

Pioneer doesn't provide a landing page redirecting to Apollo Sandbox, but it provide a `CORSMiddleware.Configuration` for the purpose of allowing Apollo Sandbox through CORS.

```swift
let cors = CORSMiddleware(configuration: .graphqlWithApolloSandbox())

app.middleware.use(cors, at: .beginning)
```

<sub>You can also just set this up on your own</sub>

Afterwards, you can go to [http://sandbox.apollo.dev/?endpoint=\<your-endpoint-here\>](http://sandbox.apollo.dev/?endpoint=http://localhost:8080/graphql) to open a instance of Apollo Sandbox set to make request to the specified endpoint.

## Banana Cake Pop

Banana Cake Pop is both a cloud hosted in browser and a downloable application GraphQL IDE developed by people over at [ChilliCream](https://chillicream.com/). Banana Cake Pop provide all features available in [GraphQL Playground](#graphql-playground) and a few more. However when using the cloud based solution, you required to specify a CORS configuration similar to [Apollo Sandbox](#apollo-sandbox).

![](/static/bananacakepop.png)

Pioneer also have `CORSMiddleware.Configuration` for the cloud based Banana Cake Pop at [https://eat.bananacakepop.com/](https://eat.bananacakepop.com/).

```swift
let cors = CORSMiddleware(configuration: .graphqlWithBananaCakePop())

app.middleware.use(cors, at: .beginning)
```

<sub>You can also just set this up on your own</sub>
