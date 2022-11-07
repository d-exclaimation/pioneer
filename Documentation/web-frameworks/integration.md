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
2. If it's in the body, get the values from the query/search parameters. (Usually for **GET**)
    - The query string should be under `query`
    - The operation name should be under `operationName`
    - The variables should be under `variables` as JSON string
        - This is probably percent encoded, and also need to be parse into `[String: Map]?` if available
    - As long the query string is accessible, the request is not malformed and we can construct a [GraphQLRequest](https://swiftpackageindex.com/d-exclaimation/pioneer/documentation/pioneer/graphqlrequest) using that.
3. If [GraphQLRequest](https://swiftpackageindex.com/d-exclaimation/pioneer/documentation/pioneer/graphqlrequest) can't be retreive by both approach 1 and 2, the request is malformed and the response should have status code of 404 Bad Request.

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

All that is needed is to serve this HTML and redirect if the IDE option is a redirect using the url given.

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