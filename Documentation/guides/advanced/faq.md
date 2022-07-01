---
icon: milestone
order: 1
---

# FAQ

This page is to host all frequently asked / common questions and answers about Pioneer that may not fit as an entire page or a subsection of another page.

## Schema

### Libraries

#### Can Pioneer support schema built from [GraphQLSwift/GraphQL](https://github.com/GraphQLSwift/GraphQL)?

Yes, you can construct a GraphQLSchema just by using [GraphQLSwift/GraphQL](https://github.com/GraphQLSwift/GraphQL) without additional library. However for a better experience, it is recommended to use something like [Graphiti](https://github.com/GraphQLSwift/Graphiti).

#### Does Pioneer support other GraphQL libraries other than Graphiti?

Yes. Pioneer have extensions for Graphiti, but it works with any schema libraries built from [GraphQLSwift/GraphQL](https://github.com/GraphQLSwift/GraphQL). You can use them by passing in the `GraphQLSchema` object.

### Scalars

#### Does the [ID](/references/structs/#id) field worked with `UUID` and/or Fluent?

Yes. The [ID](/references/structs/#id) is just a wrapper around string used to help Graphiti differentiate between `String` to an `ID` from GraphQL built in scalars.

!!!success UUID to ID extension
Since `0.8.3`, you can call the method `.toID()` or use the computed property `.id` to turn any `UUID` or `String` into an [ID](/references/structs/#id).
!!!

`UUID` can be easily parsed back into a string and used for making [ID](/references/structs/#id).

[!ref ID and UUID](/guides/advanced/fluent/#graphql-id)

### Relay

#### Does Pioneer support Connection / Relay Node and Edges?

Those are specific way of describing the schema to allow for pagination. As long as your schema library of choice (built from [GraphQLSwift/GraphQL](https://github.com/GraphQLSwift/GraphQL)) can support it, Pioneer should be able to.

Pioneer **should not** be **dictating** nor **restricting** how you would **describe your schema**, how you would **resolve them**, and how you would **store the information**.

This is for not hiding the crutial part of your server where certain issues may happen, so that you would be aware of them and tackle them according to your needs.

Hence, those capabilities are not the concern nor responsibility of Pioneer.

## Context

### GraphQL Query

#### How to get the GraphQL request query?

You can get them from the [Request](/guides/advanced/context/#request-http) object (if from http), or [GraphQLRequest](/guides/advanced/context/#graphqlrequest) object (if from ws).

To get from the [Request](/guides/advanced/context/#request-http), you will have to check if the request is **GET** or **POST**, and parse accordingly.

```swift For HTTP Context Builder
import Vapor
import Pioneer

@Sendable
func makeContext(req: Request, _: Response) throws -> Context {
    let gql: GraphQLRequest = try req.graphql
    ...
}
```

## Resolvers

### HTTP

#### How to send back cookies and headers in a resolver?

You can set them in the [Response](/guides/advanced/context/#response) object given in the context builder.
[!ref Context builder](/guides/advanced/context)

### WebSocket

#### Does Pioneer support `graphql-ws`'s `connectionParams`?

Yes, you can access it from the [Websocket Context Builder](/guides/advanced/context/#connectionparams) from the Pioneer initializer.

[!ref ConnectionParams](/guides/advanced/context/#connectionparams)

### Data Source

#### How to resolve relationship in Pioneer? and does Pioneer added shorthands to simply the process?

Relationship is resolved (technically depending on your schema library) by a relationship / field resolver. It is mostly similar to regular query resolvers but with having the parent object available usually to find the entities related to it.

No, Pioneer does not provide any shorthands for relationship as it **should not** be **dictating** nor **restricting** how you would **describe your schema**, how you would **resolve them**, and how you would **store the information**.

This is for not hiding the crutial part of your server where certain issues may happen, so that you would be aware of them and tackle them according to your needs.

Particularly with relationship, there is common problem called the N+1 which happen when querying a list of an entity that contain a relationship.

[!ref Relationship and N+1 Problem](/guides/advanced/fluent/#fluent-relationship)

### Errors

#### Is there a custom error from Pioneer?

No, there is no custom error from Pioneer (as of now), just use what works best (e.g. `Abort`). Pioneer only concern itself with encoding that error into the GraphQLError format.

#### Does Pioneer support Vapor's `Abort` and `AbortError`?

Mostly.

- If the error(s) were thrown during context building, Pioneer will use the reason to build a GraphQL formatted error and set the response status code accordingly.
  ==- Example

  ```swift Throwing Abort
  Pioneer(
    ...,
    contextBuilder: { _, _ throws in
        throw Abort(.badRequest, reason: "Some reason")
    }
  )
  ```

  ```js JSON response
  {
    "errors": [
      {
        "message": "Some reason"
      }
    ]
  }

  ```

  ```http Response Status Code
  HTTP Response 400 Bad Request
  ```

  ===

- If the error(s) were thrown in the resolver functions, Pioneer will only throw back a GraphQL formatted error with the description of the error thrown but will not set the response status (unless it was set manually into the response object during the resolving function).

  ==- Example

  ```swift Throwing Error
  struct Resolver {
      func error(_: Context, _: NoArguments) async throws -> String {
          throw Abort(.badRequest, reason: "Some Reason")
      }
  }

  ```

  ```js JSON response
  {
    "errors": [
      {
        "message": "Abort.400: Some reason",
        "locations": [
          {
            "line": 15,
            "column": 3
          }
        ],
        "path": ["error"]
      }
    ]
  }

  ```

  ===

## Streaming

### EventStream

#### Why does Pioneer only support `AsyncSequence` (and [AsyncEventStream](/features/async-event-stream/#asynceventstream))?

This is a limitation when resolving subscription, where there is not much that can be done until the subscription result is casted to another type of `EventStream`. Pioneer uses the `AsyncEventStream` which can be built from any `AsyncSequence` because it is a built-in protocol from Swift Standard Library and other streaming libraries are likely to support it as well.

#### Does Pioneer support [RxSwift](https://github.com/ReactiveX/RxSwift) and the [GraphQLRxSwift](https://github.com/GraphQLSwift/GraphQLRxSwift)?

Not directly support [RxSwift](https://github.com/ReactiveX/RxSwift). However since RxSwift 6.5.0, RxSwift's Observables can be converted into an `AsyncThrowingStream` (which is compatible with `AsyncEventStream`, even with automatic termination), which does meant it can be used with Pioneer's [AsyncEventStream](/features/async-event-stream/#asynceventstream).

However, Pioneer is not compatible with [GraphQLRxSwift](https://github.com/GraphQLSwift/GraphQLRxSwift), and all [RxSwift](https://github.com/ReactiveX/RxSwift)'s observable must be converted into an `AsyncSequence`.

### PubSub

#### Does Pioneer provide an [AsyncPubSub](/references/async-pubsub.md) that is backed by Redis?

No, Pioneer only provide [AsyncPubSub](/references/async-pubsub.md), the in-memory implementation [PubSub](/references/protocols/#pubsub). However, Pioneer does export the [PubSub](/references/protocols/#pubsub) protocol to allow custom implemenation that have similar API with [AsyncPubSub](/references/async-pubsub.md).

!!!success RedisPubSub
Implementation of Redis backed [PubSub](/references/protocols/#pubsub) is available under the package [PioneerRedisPubSub](https://github.com/d-exclaimation/pioneer-redis-pubsub). Alternatively, you could build your own implementation using this [example](/guides/advanced/subscriptions/#redis-example) as a starting point.
!!!

[!ref PubSub as a protocol](/guides/advanced/subscriptions/#pubsub-as-protocol)

## Vapor

### HTTP

#### Can I opt out from Pioneer's routing and set my own routes, while still have Pioneer handle all HTTP request?

Yes, you can using the [httpHandler(req:)](/references/pioneer/#httphandler). In which, you can perform code before and after the GraphQL operation by the handler.

[!ref Manual HTTP Routing](/features/graphql-over-http/#manual-http-routing)

### WebSocket

#### Can I opt out from Pioneer's routing and set my own routes, while still have Pioneer handle all WebSocket operations?

Yes, you can using the [webSocketHandler(req:)](/references/pioneer/#websockethandler). However different from HTTP, you can manually set the route only for the upgrade request, but you cannot intercept and manually handle WebSocket messages.

[!ref Manual WebSocket Routing](/features/graphql-over-websocket/#manual-websocket-routing)

## General

### Overview

#### How does Pioneer work in a GraphQL Vapor application?

Pioneer work by sitting between your GraphQL schema and your Vapor application. It handles all necessary features to let your GraphQL schema work under HTTP and WebSocket, while being as unopinionated and configurable (when it makes sense) as possible.

To put it simply, It's like a translator that can translate GraphQL to regular HTTP / WebSocket and vice versa.

### Swift

#### Why does Pioneer only support macOS v12 and up?

Pioneer only support v12 and up to make sure that Swift 5.5 Concurrency is available as it heavily utilize all parts of Swift 5.5 concurrency features (e.g. async await, actors, and async sequences).
