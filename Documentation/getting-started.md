---
icon: zap
title: Getting started
order: 100
---

# Get started with Pioneer

This tutorial will help you get started with building a GraphQL API using Pioneer.

!!!info 
This tutorial assumes that you are familiar with the command line, Swift, and Swift Package Manager and have installed a recent Swift version. 
!!!

## 1: New Swift project 

Go to a directory where you want to create the project on.

Setup a skeleton of the executable using Swift package manager by running:

```bash
swift package init --type executable
```

The project directory should now contains a `Package.swift` file.

## 2: Dependencies

For this tutorial, we will be using [Vapor](https://github.com/vapor/vapor) as the web framework and [Graphiti](https://github.com/GraphQLSwift/Graphiti) to built our GraphQL schema. 

!!!success Compabilitiy
Pioneer comes with first-party support for [Vapor](https://github.com/vapor/vapor) and [Graphiti](https://github.com/GraphQLSwift/Graphiti), but they are not restricted to both packages.
!!!

### Adding dependencies

Add these dependencies and [Pioneer](/) to the `Package.swift`

```swift # Package.swift
let package = Package(
    dependencies: [
        .package(url: "https://github.com/GraphQLSwift/Graphiti.git", from: "1.2.1"),
        .package(url: "https://github.com/vapor/vapor.git", from: "4.67.1"),
        .package(url: "https://github.com/d-exclaimation/pioneer", from: "1.0.0-beta")
    ],
    targets: [
        .target(
            name: "<project-name>",
            dependencies: [
                .product(name: "Pioneer", package: "pioneer"),
                .product(name: "Graphiti", package: "Graphiti"),
                .product(name: "Vapor", package: "vapor")
            ]
        )
    ]
)
```

### Using Swift 5.5 or higher

We will also restrict the platform of the project to macOS v12 or higher, to allow the use of Swift Concurrency.

```swift #2-4
let package = Package(
    platforms: [
        .macOS(.v12)
    ],
    // ...
)
```

## 3: Define entities and context

Continuing from the setup, now we will be declaring entities for the GraphQL API.

### Book entity

We'll create a simple `Book` entity.

```swift # Book.swift
import struct Pioneer.ID

struct Book: Identifiable {
    var id: ID
    var title: String
}
```

!!!success ID
Pioneer provide a struct to define [ID](https://swiftpackageindex.com/d-exclaimation/pioneer/documentation/pioneer/id) from a `String` or `UUID` which will be differentiable from a regular `String` by [Graphiti](https://github.com/GraphQLSwift/Graphiti).

[ID](https://swiftpackageindex.com/d-exclaimation/pioneer/documentation/pioneer/id) are commonly used scalar in GraphQL use to identify types.
!!!

### Context

Context is a useful type that can be generated for each request and can be used for many purpose such as: 
- Reading request-specific header value,
- Setting response headers and cookies, or 
- Performing dependency injection to each resolver functions

For this tutorial, we will create simple context type to hold both the Vapor's `Request` and `Response` object.

```swift # Context.swift
import class Vapor.Request
import class Vapor.Response

struct Context {
    var req: Request
    var res: Response
}
```

## 4: Define data source

Pioneer doesn't dictate where the resolvers get their data from and thus, it can be use with any data source (any databases, any ORMs, etc.).

For simplicity, we will simple hardcode the value and use actor to store it.

```swift # Books.swift
actor Books {
    private var books: [Book.ID: Book] = [:]

    func create(book: Book) -> Book? {
        guard case .none = books[book.id] else {
            return nil
        }
        books[book.id] = book
        return book
    }

    func all() -> [Book] {
        return books.values.map { $0 }
    }

    enum Errors: Error {
        case duplicate(id: Book.ID)
    }

    static let shared: Books = .init()
}
```

## 5: Define resolver

Resolvers tell GraphQL schema how to fetch the data associated with a particular type. 

### Resolver 
 
In [Graphiti](https://github.com/GraphQLSwift/Graphiti), this is done with a seperate resolver struct.

```swift # Resolver.swift
struct Resolver {}
```

### Query resolver

Let's now add a resolver to query all the books

```swift #1,4-6
import struct Graphiti.NoArguments

struct Resolver {
    func books(ctx: Context, args: NoArguments) async -> [Book] {
        await Books.shared.all()
    }
}
```

### Mutation resolver and arguments

For a mutation, arguments may be necessary to provide information to create a new instance of a type.

In [Graphiti](https://github.com/GraphQLSwift/Graphiti), this is done with a seperate argument struct which must be `Decodable`.

```swift #2,9-11,13-21
import struct Graphiti.NoArguments
import struct Vapor.Abort

struct Resolver {
    func books(ctx: Context, args: NoArguments) async -> [Book] {
        await Books.shared.all()
    }

    struct NewArgs: Decodable {
        var title: String
    }

    func newBook(ctx: Context, args: NewArgs) async throws -> Book {
        let book = await Books.shared.create(
            book: Book(id: .uuid(), title: args.title)
        )
        guard let book else {
            throw Abort(.internalServerError)
        }
        return book
    }
}
```

## 6: Define Schema

Every GraphQL server uses a schema to define the structure of data that clients can query. 

In [Graphiti](https://github.com/GraphQLSwift/Graphiti), schema can be declared using Swift code which allow type safety.

+++ Schema.swift
```swift # 
import Graphiti
import struct Pioneer.ID

func schema() throws -> Schema<Resolver, Context> {
    .init {
        // Adding ID as usable scalar for Graphiti
        Scalar(ID.self)

        // The Book as a GraphQL type with all its properties as fields
        Type(Book.self) {
            Field("id", at: \.id)
            Field("title", at: \.title)
        }

        Query {
            // The root query field to fetch all books
            Field("books", at: Resolver.books)
        }

        Mutation {
            // The root mutation field to create a new book
            Field("newBook", at: Resolver.book) {
                // Argument for this field
                Argument("title", at: \.title)
            }
        }
    }
}
```

+++ Schema.graphql

!!!info GraphQL SDL
This is the equivalent schema in GraphQL SDL for one built with Graphiti. This is not **required** to be created.
!!!

```gql #
type Book {
  id: ID!
  title: String!
}

type Query {
  books: [Book!]!
}

type Mutation {
  newBook(title: String!): Book!
}

schema {
  query: Query
  mutation: Mutation
}
```

+++

## 7: Pioneer instance

Now, it's time to integrate Pioneer into the existing Vapor application using the resolver and schema declared before.

### Basic Vapor application

First, let's setup a basic Vapor application.

```swift # main.swift
import Vapor

let app = try Application(.detect())

defer {
    app.shutdown()
}

try app.run()
```

### Pioneer configuration

Now, create an instance of Pioneer with the desired configuration.

```swift #1,6-12 main.swift
import Pioneer
import Vapor

let app = try Application(.detect())

let server = try Pioneer(
    schema: schema(),
    resolver: Resolver(),
    httpStrategy: .csrfPrevention,
    introspection: true,
    playground: .sandbox
)

defer {
    app.shutdown()
}

try app.run()
```

### Pioneer as Vapor middleware

Finally, apply Pioneer to Vapor as a [middleware]().

```swift #18-25 main.swift
import Pioneer
import Vapor

let app = try Application(.detect())

let server = try Pioneer(
    schema: schema(),
    resolver: Resolver(),
    httpStrategy: .csrfPrevention,
    introspection: true,
    playground: .sandbox
)

defer {
    app.shutdown()
}

app.middleware.use(
    server.vaporMiddleware(
        at: "graphql",
        context: { req, res in
            Context(req, res)
        }
    )
)

try app.run()
```

!!!info

[!badge variant="info" text="Skip to the end"](#9-start-the-server)  If you don't need subscriptions.

!!!

## 8: Adding subscriptions

Subscriptions is a feature of GraphQL which allow real-time stream of data. This is usually done through WebSocket using an [additional protocol](). 

### Enabling GraphQL over WebSocket

Pioneer is already built with these feature, and all that you have to do is enable it.

```swift #10 main.swift
import Pioneer
import Vapor

let app = try Application(.detect())

let server = try Pioneer(
    schema: schema(),
    resolver: Resolver(),
    httpStrategy: .csrfPrevention,
    websocketProtocol: .graphqlWs,
    introspection: true,
    playground: .sandbox
)

defer {
    app.shutdown()
}

app.middleware.use(
    server.vaporMiddleware(
        at: "graphql",
        context: { req, res in
            Context(req, res)
        }
    )
)

try app.run()
```

### Subscription resolver

Now, let's add the subscription resolver. Pioneer can resolve subscription as long as the return value is either:
- [AsyncEventStream](https://swiftpackageindex.com/d-exclaimation/pioneer/documentation/pioneer/asynceventstream), or
- `ConcurrentEventStream`

In this tutorial, we will be using Pioneer's built in [PubSub](https://swiftpackageindex.com/d-exclaimation/pioneer/documentation/pioneer/pubsub) system and its in-memory implementation, [AsyncPubSub](https://swiftpackageindex.com/d-exclaimation/pioneer/documentation/pioneer/asyncpubsub).

```swift #1,4-5,8-9,29-31 Resolver.swift
import class GraphQL.EventStream
import struct Graphiti.NoArguments
import struct Vapor.Abort
import struct Pioneer.AsyncPubSub
import protocol Pioneer.PubSub

struct Resolver {
    private let pubsub: PubSub = AsyncPubSub()
    private let trigger = "*:book-added"

    func books(ctx: Context, args: NoArguments) async -> [Book] {
        await Books.shared.all()
    }

    struct NewArgs: Decodable {
        var title: String
    }

    func newBook(ctx: Context, args: NewArgs) async throws -> Book {
        let book = await Books.shared.create(
            book: Book(id: .uuid(), title: args.title)
        )
        guard let book else {
            throw Abort(.internalServerError)
        }
        return book
    }

    func bookAdded(ctx: Context, args: NoArguments) -> EventStream<Book> {
        pubsub.asyncStream(Book.self, for: trigger).toEventStream()
    }
}
```

### Triggering a subscription

With [PubSub](https://swiftpackageindex.com/d-exclaimation/pioneer/documentation/pioneer/pubsub), subscription value can be pushed manually from a mutation. All we have to do is to publish under the same trigger.

```swift #25 Resolver.swift
import class GraphQL.EventStream
import struct Graphiti.NoArguments
import struct Pioneer.AsyncPubSub
import protocol Pioneer.PubSub

struct Resolver {
    private let pubsub: PubSub = AsyncPubSub()
    private let trigger = "*:book-added"

    func books(ctx: Context, args: NoArguments) async -> [Book] {
        await Books.shared.all()
    }

    struct NewArgs: Decodable {
        var title: String
    }

    func newBook(ctx: Context, args: NewArgs) async throws -> Book {
        let book = await Books.shared.create(
            book: Book(id: .uuid(), title: args.title)
        )
        guard let book else {
            throw Abort(.internalServerError)
        }
        await pubsub.publish(for: trigger, payload: book)
        return book
    }

    func bookAdded(ctx: Context, args: NoArguments) -> EventStream<Book> {
        pubsub.asyncStream(Book.self, for: trigger).toEventStream()
    }
}
```

### Updating the schema

We can now add the subscription in the schema.

```swift #28-30 Schema.swift
import Graphiti
import struct Pioneer.ID

func schema() throws -> Schema<Resolver, Context> {
    .init {
        // Adding ID as usable scalar for Graphiti
        Scalar(ID.self)

        // The Book as a GraphQL type with all its properties as fields
        Type(Book.self) {
            Field("id", at: \.id)
            Field("title", at: \.title)
        }

        Query {
            // The root query field to fetch all books
            Field("books", at: Resolver.books)
        }

        Mutation {
            // The root mutation field to create a new book
            Field("newBook", at: Resolver.book) {
                // Argument for this field
                Argument("title", at: \.title)
            }
        }

        Subscription {
            SubsciptionField("bookAdded", as: Book.self, atSub: Resolver.bookAdded)
        }
    }
}
```

### WebSocket context

Due to the nature of subscription which goes through WebSocket instead of HTTP, the context is built with different types of information i.e. there is no `Response` object for WebSocket operation.

Pioneer allow a different [WebSocket context builder]() which gives a different set of arguments catered towards what will be available on a WebSocket operation.

!!!success Shared context builder
Pioneer will try to use the same context builder if not explicit given a different one for WebSocket. It will try to maintain all relevant information and inject that values into the `Request` object.
!!!

```swift #25-27 main.swift
import Pioneer
import Vapor

let app = try Application(.detect())

let server = try Pioneer(
    schema: schema(),
    resolver: Resolver(),
    httpStrategy: .csrfPrevention,
    websocketProtocol: .graphqlWs,
    introspection: true,
    playground: .sandbox
)

defer {
    app.shutdown()
}

app.middleware.use(
    server.vaporMiddleware(
        at: "graphql",
        context: { req, res in
            Context(req, res)
        },
        websocketContext: { req, payload, gql in
            Context(req, .init())
        }
    )
)

try app.run()
```


## 9: Start the server

The server is now ready!

Run the Swift project using:

```bash
swift run
```

Now, just open [http://localhost:8080/graphql](http://localhost:8080/graphql) to go the Apollo Sandbox and play with the queries, and mutations.

!!!success 🎉 Congrats

Congrats, you have just built a GraphQL server with Swift and Pioneer!

<!-- [!ref] -->
!!!