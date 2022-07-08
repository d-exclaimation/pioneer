---
icon: database
order: 80
---

# Fluent

Fluent is the most common choice of connecting to a database from a Vapor application. There can be some confusion on how to connect Fluent entities into a GraphQL Schema, so here are some information to help tackle any of those issue.

## GraphQL ID

Let's use Graphiti as the GraphQL schema library and we have a `User` fluent entity as described below.

```swift User.swift
import Foundation
import Vapor
import Fluent

final class User: Model, Content {
    static var schema: String = "users"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "name")
    var name: String

    init() { }

    init(id: UUID? = nil, name: String) {
        self.id = id
        self.name = name
    }
}
```

Describing this class and most of its properties in Graphiti should be simple enough. However as you can see here, UUID is its struct and not a primitive in the GraphQL spec.

On the other hand, Pioneer already have provided a struct for the GraphQL `ID` primitive. We can take advantage of Swift extensions and computed properties to describe the entity's `UUID` into Pioneer's `ID`.

```swift User+Graphiti.swift
import Foundation
import Pioneer

extension User {
    var gid: ID {
        id?.toID() ?? .uuid()
    }
}
```

From that, we can use the new computed properties in the schema instead of using the `id` property.

```swift Schema.swift
import Foundation
import Graphiti
import Pioneer

func schema() throws -> Schema<Resolver, Context> {
    try .init {
        ID.asScalar()

        Type(User.self) {
            Field("id", at: \.gid)
            Field("name", at: \.name)
        }

        ...
    }
}
```

## Fluent Relationship

### Relationship Resolver

Say we have a new struct `Item` that have a many to one relationship to `User`. You can easily describe this into the GraphQL schema with using Swift's extension.

```swift Item.swift
import Foundation
import Vapor
import Fluent

final class Item: Model, Content {
    static let schema = "items"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "name")
    var name: String

    @Parent(key: "user_id")
    var user: User

    init() { }

    init(name: String, userID: User.IDValue) {
        self.name = name
        self.$user.id = userID
    }
}
```

Using extensions, we can describe a custom resolver function to fetch the `User` for the `Item`.

##### Resolver on Item

```swift Item+GraphQL.swift
import Foundation
import Fluent
import Vapor
import Pioneer
import Graphiti

extension Item {
    func owner(ctx: Context, _: NoArguments) async throws -> User? {
        return try await User.find($user.id, on: ctx.req.db)
    }
}
```

!!!warning N+1 problem

In a real producation application, this example resolver is flawed with the [N+1 problem](#n1-problem).

[!ref N+1 problem](#n1-problem)
!!!

And update the schema accordingly.

```swift Schema.swift
import Foundation
import Graphiti
import Pioneer

func schema() throws -> Schema<Resolver, Context> {
    try .init {
        ID.asScalar()

        Type(User.self) {
            Field("id", at: \.gid)
            Field("name", at: \.name)
        }

        Type(Item.self) {
            Field("name", at: \.name)
            Field("owner", at: Item.owner, as: TypeReference<User>.self)
        }

        ...
    }
}
```

This approach is actually not a specific to Pioneer. You can use the same or similar solutions if you are using Vapor, Fluent, and Graphiti, albeit without some features provided by Pioneer (i.e. async await resolver, and custom ID struct).

### N+1 Problem

Imagine your graph has query that lists items

```graphql
query {
  items {
    name
    owner {
      id
      name
    }
  }
}
```

with the `items` resolver looked like

```swift Resolver.swift
struct Resolver {
    func items(ctx: Context, _: NoArguments) async throws -> [Item] {
        try await Item.query(on: ctx.req.d).all()
    }
}
```

and the `Item` has relationship resolver looked like [`Item.owner`](#resolver-on-item).

The graph will executed that `Resolver.items` function which will make a request to the database to get all items.

Furthermore for each item, the graph will also execute the `Item.owner` function which make another request to the databse to get the user with the given id. Resulting in the following SQL statements:

```SQL N+1 queries
SELECT * FROM items
SELECT * FROM users WHERE id = ?
SELECT * FROM users WHERE id = ?
SELECT * FROM users WHERE id = ?
SELECT * FROM users WHERE id = ?
SELECT * FROM users WHERE id = ?
...
```

What's worse is that certain items can be owned by the same user so these statements will likely query for the same users multiple times.

This is what's called the N+1 problem which you want to avoid. The solution? [DataLoader](#dataloader).

### DataLoader

The GraphQL Foundation provided a specification for solution to the [N+1 problem](#n1-problem) called `dataloader`. Essentially, dataloaders combine the fetching of process across all resolvers for a given GraphQL request into a single query.

!!!success DataLoader with async-await
Since `v0.5.2`, Pioneer already provide extensions to use DataLoader with async await
!!!

The package [Dataloader](https://github.com/GraphQLSwift/DataLoader) implement that solution for [GraphQLSwift/GraphQL](https://github.com/GraphQLSwift/DataLoader).

```swift Adding DataLoader
.package(url: "https://github.com/GraphQLSwift/DataLoader", from: "...")
```

After that, we can create a function to build a new dataloader for each `Request`, and update the relationship resolver to use the loader

```swift Loader and Context
struct Context {
    ...
    // Loader computed on each Context or each request
    var userLoader: DataLoader<UUID, User>
}

extension User {
    func makeLoader(req: Request) -> DataLoader<UUID, User> {
        .init(on: req.eventLoop) { keys async in
            let users = try? await User.query(on: req.db).filter(\.$id ~~ keys).all()
            return keys.map { key in
                guard let user = res?.first(where: { $0.id == key }) else {
                    return .error(GraphQLError(
                        message: "No user with corresponding key: \(key)"
                    ))
                }
                return .success(user)
            }
        }
    }
}
```

!!!success Loading Many
In cases where you have an arrays of ids of users and need to fetch those users in a relationship resolver, [Dataloader](https://github.com/GraphQLSwift/DataLoader) have a method called `loadMany` which takes multiple keys and return them all.

In other cases where you have the user id but need to fetch all items with that user id, you can just have the loader be `DataLoader<UUID, [Item]>` where the `UUID` is the user id and now `load` should return an array of `Item`.
!!!

```swift Item+GraphQL.swift
extension Item {
    func owner(ctx: Context, _: NoArguments, ev: EventLoopGroup) async throws -> User? {
        guard let uid = $user.id else {
            return nil
        }
        return try await ctx.userLoader.load(key: uid, on: ev.next()).get()
    }
}
```

Now instead of having n+1 queries to the database by using the dataloader, the only SQL queries sent to the database are:

```SQL
SELECT * FROM items
SELECT * FROM users WHERE id IN (?, ?, ?, ?, ?, ...)
```

which is significantly better.

#### EagerLoader

Fluent provides a way to eagerly load relationship which will solve the N+1 problem by joining the SQL statement.

However, it forces you fetch the relationship **regardless** whether it is requested in the GraphQL operation which can be considered **overfetching**.

```swift Resolver.swift
struct Resolver {
    func items(ctx: Context, _: NoArguments) async throws -> [Item] {
        try await Item.query(on: ctx.req.d).with(\.$user).all()
    }
}
```

```swift Item+GraphQL.swift
extension Item {
    func owner(_: Context, _: NoArguments) async -> User? {
        return $user
    }
}
```

Whether it is a better option is up to you and your use cases, but do keep in mind that GraphQL promotes the avoidance of overfetching.
