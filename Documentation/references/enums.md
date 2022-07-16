---
icon: quote
order: 80
---

# Enums

## IDE

GraphQL Hosted IDE or online redirect to a cloud based one.

[!ref GraphQL IDE Guide](/features/graphql-ide)

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
[GraphQL Playground](/features/graphql-ide/#graphql-playground) project has been [retired](https://github.com/graphql/graphql-playground/issues/1143), recommended using [GraphiQL](/features/graphql-ide/#graphiql) instead
!!!

|||

||| `graphiql`

GraphiQL Browser IDE

|||

||| `sandbox`

Embedded Apollo Sandbox Browser IDE

!!!warning Limited
The embedded version of [Apollo Sandbox](https://www.apollographql.com/docs/studio/explorer/sandbox/#embedding-sandbox) has some limitation notably the lack of subscription support that is available for the regular [Sandbox](https://studio.apollographql.com/sandbox/explorer).

Given that, the preffered / default option for `apolloSandbox` is the redirect option.
!!!

|||

||| <code>redirect(to: [Cloud](#idecloud))</code>

Redirect to a cloud based IDE

|||

||| `apolloSandbox`

Alias for the preferred Apollo Sandbox option (Currently `.redirect(to: .apolloSandbox)`)

|||

||| `disable`

Disabled any IDEs

|||

### IDE.Cloud

GraphQL cloud based IDE options.

||| `apolloSandbox`

Cloud version of Apollo Sandbox

|||

||| `bananaCakePop`

Cloud version of Banana Cake Pop

|||

## HTTPStrategy

HTTP Operation and routing strategy for GraphQL

[!ref GraphQL over HTTP Guide](/features/graphql-over-http)

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

||| `csrfPrevention`

Allow all operation through `POST`, allow only Queries through `GET`, and enable Apollo's [CSRF and XS-Search prevention](https://www.apollographql.com/docs/apollo-server/security/cors#preventing-cross-site-request-forgery-csrf)

**GET**

- [!badge variant="success" text="Query"]

**POST**

- [!badge variant="success" text="Query"] [!badge variant="warning" text="Mutation"]

|||

||| `both`

Allow all operation through `GET` and `POST`.

**GET**

- [!badge variant="success" text="Query"] [!badge variant="warning" text="Mutation"]

**POST**

- [!badge variant="success" text="Query"] [!badge variant="warning" text="Mutation"]

|||

---

### `allowed`

Get the allowed operation for aa type of HTTPMethod

=== Example

```swift
HTTPStrategy.csrfPrevention.allowed(for: .GET)
```

===

==- Options

| Name  | Type                                         | Description                                |
| ----- | -------------------------------------------- | ------------------------------------------ |
| `for` | [!badge variant="primary" text="HTTPMethod"] | The HTTP Method this operation is executed |

===

---

## WebsocketProtocol

GraphQL over Websocket sub-protocol

[!ref GraphQL over WebSocket Guide](/features/graphql-over-websocket.md)

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

## Validations

Validation strategy to add custom rules that is executed before any resolver is executed

||| `none`

No rules, skip validation

|||

||| <code>specified(\_: [[ValidationRule](#validationrule)])</code>

Multiple constant rules

|||

||| <code>computed(\_: @Sendable ([GraphQLRequest](/references/structs/#graphqlrequest)) -> [[ValidationRule](#validationrule)])</code>

Cloud version of Banana Cake Pop

|||

### `init` (Array Literal)

Construct a new Validations from an array of [ValidationRule](#validationrule), equivalent to `.specified`

=== Example

```swift
let server = Pioneer(
    schema: schema,
    resolver: .init(),
    contextBuilder: { req, res in
        Context(req: req, res: res, auth: req.headers[.authorization].first)
    },
    validationRules: [MyValidationRule()]
)
```

===

==- Options

| Name           | Type                                                | Description                |
| -------------- | --------------------------------------------------- | -------------------------- |
| `arrayLiteral` | [!badge variant="warning" text="ValidationRule..."] | An array of ValidationRule |

===

### `init` (Nil Literal)

Construct a new Validations from a nil, equivalent to `.none`

=== Example

```swift
let server = Pioneer(
    schema: schema,
    resolver: .init(),
    contextBuilder: { req, res in
        Context(req: req, res: res, auth: req.headers[.authorization].first)
    },
    validationRules: nil
)
```

===

### ValidationRule

Typealias for `@Sendable (ValidationContext) -> Visitor`
