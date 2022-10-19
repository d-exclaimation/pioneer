---
icon: workflow
order: 70
---

# Flow

This page describe the flow and more detailed overview on how Pioneer works.

## Pioneer, Vapor, and the Schema

On a high level, Pioneer acts as a translator for HTTP and WebSocket to GraphQL that sits between your Vapor server and your GraphQL schema (and resolvers).

```mermaid
%%{init: { 'theme': 'base' }%%
graph LR
    A[Vapor] -->|Request| B[Pioneer]
    B -->|GraphQL Operation| C[GraphQL Schema]
    C -->|GraphQL Result| B
    B -->|Response| A
```
<small> HTTP / WebSocket Requests are translated into GraphQL operation, and GraphQL results are translated back into proper HTTP / WebSocket Responses </small>

### HTTP Request into GraphQL operation

Pioneer follows [GraphQL over HTTP spec](https://graphql.org/learn/serving-over-http/) to handle any HTTP requests.

#### Request to Response
Pioneer add some additional checks and processes to the overall GraphQL process either to validate request or to proper format and encode responses.
```mermaid
%%{init: { 'theme': 'base' }%%
graph TB
    A(Request)
    A -->|/graphql| B[CSRF Preventions]
    A -->|/playground| Z[GraphQL IDE]
    B -->|Passed| C[HTTP Strategy Checks]
    B -->|Blocked| X(GraphQLError)
    C -->|Allowed| D[Validations]
    C -->|Denied| X
    D -->|No Error| E[Context Builder]
    D -->|Errors| X
    E -->|Context Built with No Error| F[Operation Executor]
    E -->|Errors| X
    F -->|Data or Errors| G(GraphQLResult)
    X -->|With HTTP Status Code| G
    G --> Y(Response)
    
```

#### Operation Executor

The operation executor will handle passing down the validated AST from the operation to the schema to be executed.

```mermaid
%%{init: { 'theme': 'base' }%%
flowchart LR
    a(Request) --> b[Context Builder]
    a -->|GraphQLRequest| c
    b -->|Context| c
    subgraph one [Operation Executor]
    c[Source parsing] -->|AST| d[Validations]
    d -->|AST| e[Schema]
    end
    e -->|Data and Errors| f(GraphQLResult)
    d -->|Errors| f
    c -->|Errors| f
    b -->|Errors| f
```

### WebSocket into GraphQL operation

WebSocket works differently from HTTP. Pioneer follow 2 [GraphQL over WebSocket](/features/graphql-over-websocket.md) protocols, [subscriptions-transport-ws (`graphql-ws`)](https://github.com/apollographql/subscriptions-transport-ws/blob/master/PROTOCOL.md) and [graphql-ws (`graphql-transport-ws`)](https://github.com/enisdenjo/graphql-ws/blob/master/PROTOCOL.md). There are different process involved depending on the type of operations, and additional initialisation process for setting up WebSocket and the appropriate actors. 

```mermaid
%%{init: { 'theme': 'base' }%%
graph TB
    a[Request] -->|/graphql/websocket| b[Initialisation Checks]
    b -->|Passed| c[Connection]
    b -->|Failed| x[GraphQLError]
    c -->|GraphQL Operation| e
    subgraph one [Probe]
      e[Connections Managing] -->|Intent| g[[Drone]]
    g --> |Subscription Value| g
    end
    g -->|GraphQLResult| c
```


#### WebSocket connection initialisation

Pioneer will manually handle the protocol upgrade HTTP request to initialise the WebSocket connection.

Depending on which protocol is being used, the initialisation process might defer slightly, but the general ideas are:

1. The `Sec-WebSocket-Protocol` will be matched with the chosen [GraphQL over WebSocket protocol](/features/graphql-over-websocket.md).
2. Each connection will be assigned a unique process identifier (`pid`).
3. A timeout task will be created for the `pid` for a specified length.
4. Pioneer will now wait for a initialisation message / handshake (according to the chosen [protocol](/features/graphql-over-websocket.md) specifications).
    - If a initialisation message is received, the timeout task will be cancelled and a process is created using the `pid` before sending it to the connections actor (`Probe`).
    - If no initialisation message is received before the timeout, the connection will be closed immediately

```mermaid
%%{init: { 'theme': 'base' }%%
graph LR
  a[Upgrade HTTP] --> b[Protocol Matching]
  b -->|pid| c{Wait for initialisation?}
  c -->|Initialisation| e(Process)
  c -->|Timeout| f(Close connection)
  subgraph one [Probe]
    e
  end
```

#### WebSocket operation requests
Operations are decoded by the chosen protocol into intents which are understandable by the handlers.

- If the intent is to run a query or mutation (stateless operation), `Probe` will immediately execute the operation given using the schema on a seperate `Task`. Once the `GraphQLResult` is returned, it will sent a `Next` message using the protocol and another message `Complete` to indicate the end of the operation.
- If the intent is to run a subscription (stateful operation), Probe will delegate the operation to the connection specific `Drone`. `Drone` will then execute the operation, subscribe to the [AsyncEventStream](/features/async-event-stream.md) on a seperate `Task`, and send back each value to itself before sending a `Next` message with the value.

```mermaid
%%{init: { 'theme': 'base' }%%
graph LR
    c[Connection] -->|WebSocket Message| d[Protocol] -->|Intent| e
    subgraph one [Probe]
      e[Connections Managing] -->|Subscription| i
      e -->|Query / Mutation| t[Schema] -->|Next + Complete| d
      subgraph two [Drone]
        i[Operations Managing] -->|Subscription| g[Schema]
        i --> |Stream value| i
        g --> |AsyncEventStream| i
      end
    end
    i -->|Next / Complete| d
    d -->|WebSocket Message| c
```