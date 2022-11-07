---
icon: file-binary
order: 80
---

# GraphQL Over HTTP

!!!warning 
You're viewing documentation for a previous version of this software. Switch to the [latest stable version](/)
!!!

GraphQL spec define how a GraphQL operation is supposed to be performed through HTTP. The spec specify that operations can be done through either **GET** and **POST** request. Both of these are supported by Pioneer.

## HTTP Strategy

Pioneer have a feature to specify how operations can be handled through HTTP. There are situations where a GraphQL API should not perform something like mutations through HTTP **GET**, or the user of the library preffered just using HTTP **POST** for all operations (excluding subscriptions).

`HTTPStrategy` is a enum that can be passed in as one of the arguments when initializing Pioneer to specify which approach you prefer.

```swift
Pioneer(
    ...,
    httpStrategy: .onlyPost
)
```

Here are the available strategies:

| HTTPStrategy             | GET                                                                                | POST                                                                                 |
| ------------------------ | ---------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------ |
| `onlyPost`               | -                                                                                  | [!badge variant="success" text="Query"] [!badge variant="warning" text="Mutation"]   |
| `onlyGet`                | [!badge variant="success" text="Query"] [!badge variant="warning" text="Mutation"] | -                                                                                    |
| `queryOnlyGet` (default) | [!badge variant="success" text="Query"]                                            | [!badge variant="success" text="Query"] [!badge variant="warning" text="Mutation"]   |
| `mutationOnlyPost`       | [!badge variant="success" text="Query"] [!badge variant="warning" text="Mutation"] | [!badge variant="warning" text="Mutation"]                                           |
| `splitQueryAndMutation`  | [!badge variant="success" text="Query"]                                            | [!badge variant="warning" text="Mutation"]                                           |
| `csrfPrevention`         | [!badge variant="success" text="*Query"]                                           | [!badge variant="success" text="*Query"] [!badge variant="warning" text="*Mutation"] |
| `both`                   | [!badge variant="success" text="Query"] [!badge variant="warning" text="Mutation"] | [!badge variant="success" text="Query"] [!badge variant="warning" text="Mutation"]   |

_\*: Apollo's [CSRF and XS-Search prevention](https://www.apollographql.com/docs/apollo-server/security/cors#preventing-cross-site-request-forgery-csrf) is enabled. More [here](#csrf-and-xs-search)_

## Security

### CORS

[Cross-Origin Resource Sharing]() (CORS) is an HTTP-header-based protocol that enables a server to dictate which origins can access its resources. Put another way, your server can specify which websites can tell a user's browser to talk to your server, and precisely which types of HTTP requests are allowed.

By default, Pioneer does not enable CORS behavior but it provide a couple helper for configuring CORS.

!!!info Beginning and Before
Any CORS middleware should be applied before Pioneer's `applyMiddleware` and should be set to only for `.beginning`.
!!!

#### With Apollo Sandbox

Pioneer provide a helper static function to create a `CORSMiddleware.Configuration` that enable CORS for Apollo Sandbox (Cloud version) and allow for additional headers and enabling credentials.

+++ Default

```swift
let cors = CORSMiddleware(configuration: .graphqlWithApolloSandbox())

app.middleware.use(cors, at: .beginning)
```

+++ Additional origins

```swift
let cors = CORSMiddleware(
    configuration: .graphqlWithApolloSandbox(origins: ["https://mywebsite.com"])
)

app.middleware.use(cors, at: .beginning)
```

+++ Enabling credentials

```swift
let cors = CORSMiddleware(
    configuration: .graphqlWithApolloSandbox(
        origins: ["https://mywebsite.com"],
        credentials: true
    )
)

app.middleware.use(cors, at: .beginning)
```

+++ Additional headers

```swift
let cors = CORSMiddleware(
    configuration: .graphqlWithApolloSandbox(
        origins: ["https://mywebsite.com"],
        credentials: true,
        additionalHeaders: [.init("X-Apollo-Operation-Name"), .init("Apollo-Require-Preflight")]
    )
)

app.middleware.use(cors, at: .beginning)
```

+++

#### With Banana Cake Pop

Similarly, Pioneer provide also provide static function to create a `CORSMiddleware.Configuration` that enable CORS for Banana Cake POp (Cloud version) and allow for additional headers and enabling credentials.

+++ Default

```swift
let cors = CORSMiddleware(configuration: .graphqlWithBananaCakePop())

app.middleware.use(cors, at: .beginning)
```

+++ Additional origins

```swift
let cors = CORSMiddleware(
    configuration: .graphqlWithBananaCakePop(origins: ["https://mywebsite.com"])
)

app.middleware.use(cors, at: .beginning)
```

+++ Enabling credentials

```swift
let cors = CORSMiddleware(
    configuration: .graphqlWithBananaCakePop(
        origins: ["https://mywebsite.com"],
        credentials: true
    )
)

app.middleware.use(cors, at: .beginning)
```

+++ Additional headers

```swift
let cors = CORSMiddleware(
    configuration: .graphqlWithBananaCakePop(
        origins: ["https://mywebsite.com"],
        credentials: true,
        additionalHeaders: [.init("X-Apollo-Operation-Name"), .init("Apollo-Require-Preflight")]
    )
)

app.middleware.use(cors, at: .beginning)
```

+++

### CSRF and XS-Search

When enabling any CORS policy, usually the browser will make an additional request before the actual request, called the preflight request with the method of `OPTIONS`.
These preflight request provide headers that describe the kind of request that the potentially untrusted JavaScript wants to make. Your server returns a response with `Access-Control-*` headers describing its policies (as described above), and the browser uses that response to decide whether it's OK to send the real request.

However, the browser may not send these preflight request if the request is deemed `"simple"`. While your server can still send back `Access-Control-*` headers and let the browser know to hide the response from the problematic JavaScript, it is very likely that the GraphQL server had already executed the GraphQL operations from that "simple" request and might performed unwanted side-effects (Called the Cross Site Request Forgery).

To avoid CSRF (and also XS-Search attacks), GraphQL servers should refuse to execute any operation coming from a browser that has not "preflighted" that operation.

#### Enabling CSRF and XS-Search Prevention

Pioneer uses the same mechanic to prevent these types of attacks as [Apollo Server](https://www.apollographql.com/docs/apollo-server/), described [here](https://www.apollographql.com/docs/apollo-server/security/cors#preventing-cross-site-request-forgery-csrf).

!!!success CSRF Protected
If you set the http strategy to `.queryOnlyGet` (which is the default) or `.onlyPost` and as long as you ensure that only mutations can have side effects, you are somewhat protected from the "side effects" aspect of CSRFs even without enabling CSRF protection.
!!!

To enable it, just change the [HTTPStrategy](#http-strategy) to `.csrfPrevention`, which will add additional restrictions to any GraphQL request going through HTTP.

```swift
let server = Pioneer(
    ...,
    httpStrategy: .csrfPrevention
)
```

#### Consideration

While this mechanic is recommended to improve your server security, there is a couple consideration to be take account of.

It should have no impact on legitimate use of your graph except in these two cases:

- You have clients that send GET requests and are not Apollo Client Web, Apollo iOS, or Apollo Kotlin
- You implemented and have enabled file uploads through your GraphQL server using `multipart/form-data`.

If either of these apply to you and you want to keep the prevention mechanic, you should configure the relevant clients to send a non-empty `Apollo-Require-Preflight` header along with all requests.

## Manual HTTP Routing

In cases where the routing configuration by Pioneer when using [`.applyMiddleware`](https://swiftpackageindex.com/d-exclaimation/pioneer/documentation/pioneer/pioneer/applymiddleware(on:at:bodystrategy:)) is insufficient to your need, you can opt out and manually set your routes, have Pioneer still handle GraphQL operation, and even execute code on the incoming request before Pioneer handles the GraphQL operation(s).

To do that, you can utilize the newly added [`.httpHandler(req:)`](https://swiftpackageindex.com/d-exclaimation/pioneer/documentation/pioneer/pioneer/httphandler(req:)) method from Pioneer, which will handle incoming `Request` and return a proper GraphQL formatted`Response`.

!!!success Manual WebSocket Routing
Pioneer also provide handler to manually setting routes for WebSocket

[!ref Manual WebSocket Routing](./graphql-over-websocket/#manual-websocket-routing)
!!!

!!!success Custom ContentEncoder
Since `v0.10.0`, There is `.httpHandler(req:using:)` method that can take a custom `ContentEncoder`
!!!

```swift
let app = try Application(.detect())
let server = try Pioneer(...)

app.group("api") {
    app.post("graphql") { req async throws in
        // Do something before the operation start
        let res = try await server.httpHandler(req: req)
        // Do something after the operation ended
        return res
    }
}
```

### Consideration

The [`.httpHandler(req:)`](https://swiftpackageindex.com/d-exclaimation/pioneer/documentation/pioneer/pioneer/httphandler(req:)) method has some behavior to be aware about. Given that it is a method from the Pioneer struct, it still uses the configuration set when creating the Pioneer server, such as:

1. It will still use the [HTTPStrategy](#http-strategy) and check if the request is valid / allowed to go through.
   - For example, if you set a **GET** route using this but the httpStrategy is set to `.onlyPost`, this handler won't accept **GET** request for all GraphQL operations and will just throw an error.
   - On the other hand, if the httpStrategy is set to `.csrfPrevention`, it will still perform checks to make sure the server is safe from CSRF and XS-Search attacks.
2. While the handler can throw an error, It will encode all errors thrown by any resolver(s) and any context builder(s) into the Response. The error thrown by the handler happened only due to failure in encoding such response.
   - For example, say your resolver or context builder explicitly throw an error, Pioneer will catch these errors, format them as GraphQLError (in a GraphQLResult), encode them into the Response object content, so handler will not rethrow the error and instead return a response object.
