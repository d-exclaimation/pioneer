---
icon: file-binary
order: 80
---

# GraphQL Over HTTP

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

| HTTPStrategy             | GET                                                                                | POST                                                                               |
| ------------------------ | ---------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------- |
| `onlyPost`               | -                                                                                  | [!badge variant="success" text="Query"] [!badge variant="warning" text="Mutation"] |
| `onlyGet`                | [!badge variant="success" text="Query"] [!badge variant="warning" text="Mutation"] | -                                                                                  |
| `queryOnlyGet` (default) | [!badge variant="success" text="Query"]                                            | [!badge variant="success" text="Query"] [!badge variant="warning" text="Mutation"] |
| `mutationOnlyPost`       | [!badge variant="success" text="Query"] [!badge variant="warning" text="Mutation"] | [!badge variant="warning" text="Mutation"]                                         |
| `splitQueryAndMutation`  | [!badge variant="success" text="Query"]                                            | [!badge variant="warning" text="Mutation"]                                         |
| `both`                   | [!badge variant="success" text="Query"] [!badge variant="warning" text="Mutation"] | [!badge variant="success" text="Query"] [!badge variant="warning" text="Mutation"] |

## Context, Request and Response

Pioneer provide a similar solution to `apollo-server-express` in handling fetching the raw http requests and sending back custom responses. It provide both in the context builder that needed to be provided when constructing Pioneer. This request and response will be request-specific / different for each GraphQL HTTP request.

```swift main.swift
import Pioneer
import Vapor

let app = try Application(.detect())

@Sendable 
func getContext(req: Request, res: Response) -> Context {
    // Do something extra if needed
    Context(req: req, res: req)
}

let server = Pioneer(
    schema: schema,
    resolver: Resolver(),
    contextBuilder: getContext,
    websocketProtocol: .graphqlWs,
    introspection: true,
    playground: .graphiql
)
```

!!!info Websocket Context Builder
From `v0.7.0`, You can now provide a different websocket context builder by passing `websocketContextBuilder`.
[!ref Websocket Context](/guides/features/graphql-over-websockets/#websocket-context)
!!!

!!!success Shared Context Builder
By default if you don't provide a seperate context builder for websocket, Pioneer will try to use the regular `contextBuilder`, by passing a custom request and a dummy response (that serve no value).

==- Custom Request for Websocket
The custom request will similar to the request used to upgrade to websocket but will have:
- The headers taken from `"header"/"headers"` value from the `ConnectionParams`
- The query parameters taken from `"query"/"queries"/"queryParams"/"queryParameters"` value from the `ConnectionParams`
- The body from the `GraphQLRequest`

!!!warning Only when using shared builder
These addition only apply when using shared context builder. If not, the request will be the exact one from the upgrade request with no custom headers

===
!!!

### Request

The request given is directly from Vapor, so you can use any method you would use in a regular Vapor application to get any values from it.

```swift Getting a cookie example
struct Resolver {
    func someCookie(ctx: Context, _: NoArguments) async -> String {
        return ctx.req.cookies["some-key"]
    }
}
```

### Response

Pioneer already provided the response object in the context builder that is going to be the one used to respond to the request. You don't need return one, and instead just mutate its properties.

!!!warning Returning custom response
There is currently no way for a resolver function to return a custom response. Graphiti only take functions that return the type describe in the schema, and Pioneer also have to handle encoding the returned value into a response that follow the proper GraphQL format.
!!!

```swift Setting a cookie example
func users(ctx: Context, _: NoArguments) async -> [User] {
    ctx.response.cookies["refresh-token"] = /* refresh token */
    ctx.response.cookies["access-token"] = /* access token */
    return await getUsers()
}
```
