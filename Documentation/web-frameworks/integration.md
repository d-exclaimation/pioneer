---
icon: server
title: Integrations
order: -1
---

# Integrations

## Open-Source Integrations

Exisiting first-party of community maintained integrations for Pioneer:

| Web Framework | Integration Package |
|--------|-------------|
| [Vapor](https://vapor.codes) | [Pioneer](/web-frameworks/vapor) |

## Building integrations

!!!success
This section is for *authors* of web frameworks integrations. Before building a new integration, it's recommended seeing if there's an [integration](#open-source-integrations) for your framework of choice that suits your needs
!!!

### Implementing GraphQL over HTTP 

First, the HTTP layer. Pioneer provide a method [.executeHTTPGraphQLRequest](https://swiftpackageindex.com/d-exclaimation/pioneer/documentation/pioneer/pioneerexecutehttpgraphqlrequest(for:with:using)) which is the base layer of an GraphQL would look like HTTP handler.

All that is missing to use that method is translating the web-framework native request object into [HTTPGraphQLRequest](https://swiftpackageindex.com/d-exclaimation/pioneer/documentation/pioneer/pioneer/httpgraphqlrequest).

#### Mapping into [HTTPGraphQLRequest](https://swiftpackageindex.com/d-exclaimation/pioneer/documentation/pioneer/pioneer/httpgraphqlrequest)

[HTTPGraphQLRequest](https://swiftpackageindex.com/d-exclaimation/pioneer/documentation/pioneer/pioneer/httpgraphqlrequest) only require 3 properties: the GraphQLRequest object, the HTTP headers, and the HTTP method.

```swift #2-4
struct HTTPGraphQLRequest {
    var request: GraphQLRequest
    var headers: HTTPHeaders
    var method: HTTPMethod
}
```

The important part is parsing into [GraphQLRequest](https://swiftpackageindex.com/d-exclaimation/pioneer/documentation/pioneer/graphqlrequest). A recommended approach in parsing is:

1. Parse [GraphQLRequest](https://swiftpackageindex.com/d-exclaimation/pioneer/documentation/pioneer/graphqlrequest) from the body of a request. (Usually for **POST**)
2. If it's not in the body, get the values from the query/search parameters. (Usually for **GET**)
    - The query string should be under `query`
    - The operation name should be under `operationName`
    - The variables should be under `variables` as JSON string
        - This is probably percent encoded, and also need to be parse into `[String: Map]?` if available
    - As long the query string is accessible, the request is not malformed and we can construct a [GraphQLRequest](https://swiftpackageindex.com/d-exclaimation/pioneer/documentation/pioneer/graphqlrequest) using that.
3. If [GraphQLRequest](https://swiftpackageindex.com/d-exclaimation/pioneer/documentation/pioneer/graphqlrequest) can't be retreive by both approach 1 and 2, the request is malformed and the response could also have status code of 400 Bad Request.

==- Example

```swift #
import class WebFramework.Request

extension Request {
    var graphql: HTTPGraphQLRequest? {
        switch (method) {
            // Parsing from body for POST
            case .post:
                guard let gql = try? JSONDecoder().decode(GraphQLRequest.self, from: self.body) else {
                    return nil
                }
                return .init(request: gql, headers: headers, method: method)

            // Parsing from query/search params for GET
            case .get:
                guard let query = self.search["query"] else {
                    return nil
                }
                let operationName = self.search["operationName"]
                let variables = self.search["variables"]?
                    .removingPercentEncoding
                    .flatMap {
                        $0.data(using: .utf8)
                    }
                    .flatMap {
                        try? JSONDecoder().decode([String: Map].self, from: $0)
                    }
                let gql = GraphQLRequest(query: query, operationName: operationName, variables: variables)
                return .init(request: gql, headers: headers, method: method)
            
            default:
                return nil
        }
    }
}
```

===

#### Getting the context

It's important that the context should be computed / derived for each request. By convention, it's best to allow user of the integration to compute the context from the request and the response object of the web-framework.

If the compute function is allowed to be asynchronous, make sure to make it `Sendable` conformance by adding the `@Sendable` function wrapper.

==- Example

```swift #
import class WebFramework.Request
import class WebFramework.Response
import struct Pioneer.Pioneer

extension Pioneer {
    typealias WebFrameworkHTTPContext = @Sendable (Request, Response) async throws -> Context
}
```

===

#### Executing and using [HTTPGraphQLResponse](https://swiftpackageindex.com/d-exclaimation/pioneer/documentation/pioneer/pioneer/httpgraphqlresponse)

Once, there is a way to retreive [HTTPGraphQLRequest](https://swiftpackageindex.com/d-exclaimation/pioneer/documentation/pioneer/pioneer/httpgraphqlrequest) and the context. All is needed is to execute the request and mapped the [HTTPGraphQLRequest](https://swiftpackageindex.com/d-exclaimation/pioneer/documentation/pioneer/pioneer/httpgraphqlresponse) into the web-framework response object.

```swift #2-3
struct HTTPGraphQLResponse {
    var result: GraphQLResult
    var status: HTTPResponseStatus
}
```

==- Example

```swift #9-14,16-19,23-25
import class WebFramework.Request
import class WebFramework.Response
import struct Pioneer.Pioneer
import struct GraphQL.GraphQLJSONEncoder

extension Pioneer {
    public func httpHandler(req: Request, context: @escaping WebFrameworkHTTPContext) async throws -> Response {
        do {
            // Parsing HTTPGraphQLRequest and Context 
            guard let httpreq = req.graphql else {
                return Response(status: .badRequest)
            }
            let res = Response()
            let context = try await context(req, res)

            // Executing into GraphQLResult
            let httpRes = await executeHTTPGraphQLRequest(for: httpreq, with: context, using: req.eventLoop)
            res.body = try GraphQLJSONEncoder().encode(httpres.result)
            res.status = httpRes.status

            return res
        } catch {
            // Format error caught into GraphQLResult
            let body = try GraphQLJSONEncoder().encode(GraphQLResult(data: nil, errors: [.init(error)]))
            return Response(status: .internalServerError, body: body)
        }
    }
}
```
===

### Implementing GraphQL IDE 

This is part is relatively simple, send back the web-framework response that contains the HTML for the given IDE or a redirect if the IDE was set to be a redirect. 

The HTML for each type of IDE are available as computed properties of Pioneer. The URL for the Cloud IDEs are accessible property.

All that is needed is to serve this HTML and redirect if the IDE option is a redirect using the URL given.

==- Example

```swift #7-15
import class WebFramework.Request
import class WebFramework.Response
import struct Pioneer.Pioneer

extension Pioneer {
    func ideHandler(req: Request) -> Response {
        switch (playground) {
            case .sandbox:
                return serve(html: embeddedSandboxHtml)
            case .graphiql:
                return serve(html: graphiqlHtml)
            case .playground:
                return serve(html: playgroundHtml)
            case .redirect(to: let cloud):
                return Response(status: .permanentRedirect, redirect: cloud.url)
        }
    }

    func serve(html: String) -> Response {
        Response(
            status: .ok,
            headers: ["Content-Type": "text/html"],
            body: html.data(using: .utf8)
        )
    }
}
```

===

### Implemeting GraphQL over WebSocket


Implementing the WebSocket layer can be tricky to do. Pioneer already provide all the callbacks need to setup GraphQL over WebSocket, the only thing missing is to connect that to the WebSocket portion of the web-framework.

#### Upgrading HTTP Request into WebSocket

It is important that the desired web-framework can be used to perform upgrade to WebSocket from a regular HTTP requests. 

The only thing needed to be done before the upgrade is done, is to check whether the `Sec-WebSocket-Protocol` header value is matching the WebSocket protocol name

==- Example

```swift #6-12
import class WebFramework.Request
import struct WebFramework.BadRequestError
import struct Pioneer.Pioneer

extension Pioneer {
    func shouldUpgrade(req: Request) async throws -> HTTPHeaders {
        guard let req.headers[.secWebSocketProtocol].first(where: websocketProtocol.isValid) else {
            throw BadRequestError()
        }

        return req.headers
    }
}
```

===

#### Context and Guard

Before proceeding, similarly to HTTP, context is a crutial part of the GraphQL operation. By convention for WebSocket, it's best to allow user of the integration to compute the context from the request, the initial payload, and the GraphQL operation itself.

The only other addition is WebSocket guard. It is also desirable for the user to be able to perform action just after the initialisation process using the request and the initial payload.

==- Example

```swift #7-8
import class WebFramework.Request
import struct Pioneer.Pioneer
import struct Pioneer.GraphQLRequest
import enum Pioneer.Payload

extension Pioneer {
    typealias WebFrameworkWebSocketContext = @Sendable (Request, Payload, GraphQLRequest) async throws -> Context
    typealias WebFrameworkWebSocketGuard = @Sendable (Request, Payload) async throws -> Void
}
```

===

#### Making WebSocket WebSocketable

In order for Pioneer to use the web-framework specific implementation of WebSocket. The web-framework WebSocket object must conforms the [WebSocketable](https://swiftpackageindex.com/d-exclaimation/pioneer/documentation/pioneer/websocketable) protocol.

==- Example

```swift #5-7,9-11
import enum NIOWebSocket.WebSocketErrorCode
import class WebFramework.WebSocket

extension WebSocket: WebSocketable {
    public func out<S>(_ msg: S) where S: Collection, S.Element == Character {
        send(msg)
    }

    public func terminate(code: WebSocketErrorCode) async throws {
        try await close(code: code)
    }
}
```

===


#### Setting up GraphQL over WebSocket 

After the upgrade is done, there's only a few things to do:

- Create a new `UUID` to uniquely identify the connection.
- Setup `Task`s for keeping the connection alive and timeout connection if initialisation didn't happen.
    - This can be performed using the [.keepAlive](https://swiftpackageindex.com/d-exclaimation/pioneer/documentation/pioneer/pioneer/keepalive(using:)) and the [.timeout](https://swiftpackageindex.com/d-exclaimation/pioneer/documentation/pioneer/pioneer/timeout(using:keepalive)) method.
    - [.timeout](https://swiftpackageindex.com/d-exclaimation/pioneer/documentation/pioneer/pioneer/timeout(using:keepalive)) might want to be called after [.keepAlive](https://swiftpackageindex.com/d-exclaimation/pioneer/documentation/pioneer/pioneer/keepalive(using:)), because it optionally require the keep alive task as an argument.
- Creating a task or a stream to consume the incoming WebSocket messages
    - [.receiveMessage](https://swiftpackageindex.com/d-exclaimation/pioneer/documentation/pioneer/pioneer) method is used here.
    - For consuming the incoming message, if in the web-framework it is done in a callback, it is best to pipe that value into an AsyncStream first and iterate through the AsyncStream before calling the [.receiveMessage](https://swiftpackageindex.com/d-exclaimation/pioneer/documentation/pioneer/pioneer) method.
- Setting up callback for when the connection has been closed.
    - [.closeClient](https://swiftpackageindex.com/d-exclaimation/pioneer/documentation/pioneer/pioneer) method is used here.
    - It is also recommended if possible to stop the consuming incoming message here as well.

==- Example

```swift #7-15,24,27-28,31-56,59-64
import class WebFramework.Request
import class WebFramework.Response
import class WebFramework.WebSocket
import struct Pioneer.Pioneer

extension Pioneer {
    func wsHandler(
        req: Request, 
        context: @escaping WebFrameworkWebSocketContext, 
        guard: @escaping WebFrameworkWebSocketGuard
    ) async throws -> Response {
        req.upgradeToWebSocket(shouldUpgrade: shouldUpgrade(req:)) { req, ws
            onUpgrade(req: req, ws: ws, context: context, guard: `guard`)
        }
    }


    func onUpgrade(
        req: Request, 
        ws: WebSocket, 
        context: @escaping WebFrameworkWebSocketContext, 
        guard: @escaping WebFrameworkWebSocketGuard
    ) -> Void {
        let cid = UUID()

        // Keep alive and timeout task
        let keepAlive = keepAlive(using: ws)
        let timeout = timeout(using: ws, keepAlive: keepAlive)

        // Consuming incoming message
        let receiving = Task {
            let stream = AsyncStream(String.self) { con in 
                ws.onMessage(con.yield)

                con.onTermination = { @Sendable _ in 
                    guard ws.isClosed else { return }
                    _ = ws.close()
                }
            }

            for await message in stream {
                await receiveMessage(
                    cid: cid, io: ws, 
                    keepAlive: keepAlive, 
                    timeout: timeout,
                    ev: req.eventLoop, 
                    txt: message,
                    context: {
                        try await context(req, $0, $1)
                    },
                    check: {
                        try await `guard`(req, $0)
                    }
                )
            }
        }

        // Closing task
        Task {
            try await ws.onClose.get()
            receiving.cancel()
            closeClient(cid: cid, keepAlive: keepAlive, timeout: timeout)
        }
    }
}
```

===