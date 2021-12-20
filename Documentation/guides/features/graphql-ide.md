---
icon: squirrel
order: 60
---

# GraphQL IDE

GraphQL IDEs are quick and convenient ways to develop and test your GraphQL APIs, by making request on it without having to worry about setting up all the proper HTTP method, headers, and body.

!!! Introspection
Pioneer will disable any GraphQL IDE automatically regardless of the specified parameter, if introspection is disabled, as GraphQL IDE relies on introspection to provide syntax highlighting.
!!!

!!!warning Scoped route
Due to the limitation with `RoutesGroup`, Pioneer cannot infer the prefixed route when given a scoped `RoutesGroup`, and any GraphQL IDE hosted will not be able to find the correct endpoints.
!!!

## GraphiQL

GraphiQL is the official GraphQL IDE by the GraphQL Foundation. The current GraphiQL version has met feature parody with [GraphQL Playground](#graphql-playground).

![](/static/graphiql.png)

[GraphiQL](#graphiql) is self hosted in-browser version (There is an electron app for it). Pioneer can host (by default) [GraphiQL](#graphiql) at the `/playground` endpoint.

```swift
let server = Pioneer(
    ...,
    playground: .graphiql
)

server.applyMiddleware(on: app)
```

This will result in

```http
GET /graphql
POST /graphql
WS /graphql/websocket

GET /playground # (For GraphiQL)
```

## GraphQL Playground

The most common GraphQL IDE is graphql-playground which is a variant of the original GraphiQL with some added improvement, both UI and certain functionalities.

!!!warning Retired
The [GraphQL Playground](#graphql-playground) project has been [retired](https://github.com/graphql/graphql-playground/issues/1143). Pioneer will still have this option. However, it recommended to use something else as we don't recommend long-term use of this unmaintained project.
!!!

![](/static/playground.png)

[GraphQL Playground](#graphql-playground) is self-hosted in-browser version. Pioneer can host a [GraphQL Playground](#graphql-playground) at the [/playground](http://localhost:8080/playground) endpoint by specifying it in the initialzer.

```swift
let server = Pioneer(
    ...,
    playground: .playground
)

server.applyMiddleware(on: app)
```

This will result in

```http
GET /graphql
POST /graphql
WebSocket /graphql/websocket

GET /playground # (For playground)
```

## Apollo Sandbox

Apollo Sandbox is a cloud hosted in browser GraphQL IDE developed by Apollo GraphQL and their choice of replacement for [GraphQL Playground](#graphql-playground). Apollo Sandbox provide all features available in [GraphQL Playground](#graphql-playground) and more. However, this is a cloud based solution that require CORS configuration, cannot be self-hosted, and is not open source.

![](/static/sandbox.jpeg)

Pioneer can provide redirecting route (at [/playground](http://localhost:8080/playground)) to Apollo Sandbox and a `CORSMiddleware.Configuration` for the purpose of allowing Apollo Sandbox through CORS.

```swift
let server = Pioneer(
    ...,
    playground: .apolloSandbox
)
let cors = CORSMiddleware(configuration: .graphqlWithApolloSandbox())

app.middleware.use(cors, at: .beginning)

server.applyMiddleware(on: app)
```

<sub>You can also just set this up on your own</sub>

Afterwards, you can go to [http://sandbox.apollo.dev/?endpoint=\<your-endpoint-here\>](http://sandbox.apollo.dev/?endpoint=http://localhost:8080/graphql) to open a instance of Apollo Sandbox set to make request to the specified endpoint.

## Banana Cake Pop

Banana Cake Pop is both a cloud hosted in browser and a downloable application GraphQL IDE developed by people over at [ChilliCream](https://chillicream.com/). Banana Cake Pop provide all features available in [GraphQL Playground](#graphql-playground) and a few more. However when using the cloud based solution, you required to specify a CORS configuration similar to [Apollo Sandbox](#apollo-sandbox).

![](/static/bananacakepop.png)

Pioneer also can provide redirecting route (at [/playground](http://localhost:8080/playground)) to Banana Cake Pop and a `CORSMiddleware.Configuration` for for the cloud based Banana Cake Pop at [https://eat.bananacakepop.com/](https://eat.bananacakepop.com/).

```swift
let server = Pioneer(
    ...,
    playground: .bananaCakePop
)
let cors = CORSMiddleware(configuration: .graphqlWithBananaCakePop())

app.middleware.use(cors, at: .beginning)

server.applyMiddleware(on: app)
```

<sub>You can also just set this up on your own</sub>
