---
icon: quote
order: 80
---

# Enums

## IDE

GraphQL Hosted IDE or online redirect to a cloud based one.

[!ref GraphQL IDE Guide](/guides/features/graphql-ide)

!!!success Endpoint
All GraphQL IDE will be hosted or given a redirect on `"/playground"` endpoint.
!!!

!!!warning Introspection
Introspection must be set to `true` the use of any GraphQL IDE
!!!

```swift
let server = Pioneer(
    ...,
    playground: .graphiql
)
```

||| `playground`

GraphQL Playground IDE (only for [subscriptions-graphql-ws](https://github.com/apollographql/subscriptions-transport-ws)) |

!!!warning Deprecated
[GraphQL Playground](/guides/features/graphql-ide/#graphql-playground) project has been [retired](https://github.com/graphql/graphql-playground/issues/1143), recommended using [GraphiQL](/guides/features/graphql-ide/#graphiql) instead
!!!

|||

||| `graphiql`

GraphiQL Browser IDE

|||

||| `apolloSandbox`

Redirect to Apollo Sandbox

|||

||| `bananaCakePop`

Redirect to Banana Cake Pop for the cloud)

|||

||| `disable`

Disabled any IDEs

|||

## HTTPStrategy

HTTP Operation and routing strategy for GraphQL

[!ref GraphQL over HTTP Guide](/guides/features/graphql-over-http)

```swift
let server = Pioneer(
    ...,
    httpStrategy: .queryOnlyGet
)
```

||| `onlyPost`

Only allow `POST` GraphQL Request, most common choice

**POST**

- [!badge variant="success" text="Query"] [!badge variant="warning" text="Mutation"]

|||

||| `onlyGet`

Only allow `GET` GraphQL Request, not recommended for most

**GET**

- [!badge variant="success" text="Query"] [!badge variant="warning" text="Mutation"]

|||

||| `queryOnlyGet`

Allow all operation through `POST` and allow only Queries through `GET`, recommended to utilize CORS

**GET**

- [!badge variant="success" text="Query"]

**POST**

- [!badge variant="success" text="Query"] [!badge variant="warning" text="Mutation"]

|||

||| `mutationOnlyPost`

Allow all operation through `GET` and allow only Mutations through `POST`, utilize browser GET cache but not recommended

**GET**

- [!badge variant="success" text="Query"] [!badge variant="warning" text="Mutation"]

**POST**

- [!badge variant="warning" text="Mutation"]

|||

||| `splitQueryAndMutation`

Query must go through `GET` while any mutations through `POST`, follow and utilize HTTP conventions

**GET**

- [!badge variant="success" text="Query"]

**POST**

- [!badge variant="warning" text="Mutation"]

|||

||| `both`

Allow all operation through `GET` and `POST`.

**GET**

- [!badge variant="success" text="Query"] [!badge variant="warning" text="Mutation"]

**POST**

- [!badge variant="success" text="Query"] [!badge variant="warning" text="Mutation"]

|||

## WebsocketProtocol

GraphQL over Websocket sub-protocol

[!ref GraphQL over WebSocket Guide](/guides/features/graphql-over-websockets)

```swift
let server = Pioneer(
    ...,
    websocketProtocol: .graphqlWs
)
```

||| `subscriptionsTransportWs`

GraphQL over Websocket with [subscriptions-transport-ws/graphql-ws](https://github.com/apollographql/subscriptions-transport-ws)

|||

||| `graphqlWs`

GraphQL over Websocket with [graphql-ws/graphql-transport-ws](https://github.com/enisdenjo/graphql-ws)

|||

||| `disable`

Disable GraphQL over Websocket entirely.

!!!warning Disabled entirely

Using this meant no operations nor even a websocket connection is going to be accepted by the server.

!!!

|||
