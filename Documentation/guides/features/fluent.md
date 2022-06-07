---
icon: database
order: 60
---

# Fluent Integration

Fluent is the most common choice of connecting to a database from a Vapor application. There can be some confusion on how to connect Fluent entities into a GraphQL Schema.

## GraphQL ID

As an example, let's use Graphiti as the GraphQL schema library and we have a `User` fluent entity as described below.

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
        if let uuid = id?.uuidString {
            return .init(uuid)
        }
        return .uuid()
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

```swift Item+Graphiti.swift
import Foundation
import Fluent
import Vapor
import Pioneer
import Graphiti

extension Item {
    func owner(ctx: Context, _: NoArguments) async throws -> User? {
        return try await User.query(on: ctx.req.db).filter(\.$id == $user.id).first()
    }
}
```

_This example is very simple. However in a real application, you might want to use [`DataLoader`](https://github.com/GraphQLSwift/DataLoader)_

[!ref More on Relationship](/guides/getting-started/resolver.md/#relationship)

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
