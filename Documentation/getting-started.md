---
icon: zap
title: Getting started
order: 100
---

# Get started with Pioneer

This tutorial will help you get started with building a GraphQL API using Pioneer.

!!!info Swift, Swift Package Manager, CLI
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

Continuing from the setup, now we will be declaring entities and the resolvers for the GraphQL API.

We'll create a simple `Book` entity and simple context type to hold both the Vapor's `Request` and `Response` object.

```swift # Book.swift
import struct Pioneer.ID

struct Book: Identifiable {
    var id: ID
    var title: String
}
```

!!!success ID
Pioneer provide a struct to define [ID]() from a `String` or `UUID` which will be differentiable from a regular `String` by [Graphiti](https://github.com/GraphQLSwift/Graphiti).

[ID]() are commonly used scalar in GraphQL use to identify types.
!!!


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

    func create(book: Book) throws -> Book {
        guard case .none = books[book.id] else {
            throw Errors.duplicate(id: book.id)
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

In [Graphiti](https://github.com/GraphQLSwift/Graphiti), this is done with a seperate resolver struct.

```swift # Resolver.swift
struct Resolver {}
```

Let's now add a resolver to query all the books

```swift #1,4-6
import struct Graphiti.NoArguments

struct Resolver {
    func books(ctx: Context, args: NoArguments) async -> [Book] {
        await Books.shared.all()
    }
}
```

For a mutation, arguments may be necessary to provide information to create a new instance of a type.

In [Graphiti](https://github.com/GraphQLSwift/Graphiti), this is done with a seperate argument struct which must be `Decodable`.

```swift #8-15
import struct Graphiti.NoArguments

struct Resolver {
    func books(ctx: Context, args: NoArguments) async -> [Book] {
        await Books.shared.all()
    }

    struct NewArgs: Decodable {
        var title: String
    }

    func newBook(ctx: Context, args: NewArgs) async throws -> Book {
        let book = Book(id: .uuid(), title: args.title) // ID from a new UUID
        return try await Books.shared.create(book: book)
    }
}
```

## 6: Define Schema

Every GraphQL server uses a schema to define the structure of data that clients can query. 

In [Graphiti](https://github.com/GraphQLSwift/Graphiti), schema can be declared using Swift code which allow type safety.

```swift # Schema.swift
import struct Pioneer.ID
import Graphiti

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

## 7: Pioneer instance

Now, it's time to integrate Pioneer into the existing Vapor application using the resolver and schema declared before.

First, let's setup a basic Vapor application.

```swift # main.swift
import Vapor

let app = try Application(.detect())

defer {
    app.shutdown()
}

try app.run()
```

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

Finally, apply Pioneer to Vapor as a middleware.

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

## 8: Start the server

The server is now ready!

Run the Swift project using:

```bash
swift run
```

Now, just open http://localhost:8080/graphql to go the Apollo Sandbox and play with the queries, and mutations.