---
icon: people
order: 90
---

# Entities

!!!warning 
You're viewing documentation for a previous version of this software. Switch to the [latest stable version](/)
!!!

Continuing from the setup, now we will be declaring entities for the GraphQL API.

Let's say for this example, we will have a user management system where the API can be used to create, find, update, and delete user profile(s).

## User profiles

Declaring the `User` model is fairly straight forward.

```swift User.swift
struct User: Identifiable, Codable, Sendable {
    var id: UUID
    var username: String?
    var email: String
    var bio: String

    var displayName: String {
        username ?? email
    }

    var friendIDs: [UUID]
}
```

Here, we have a couple properties and some computed ones as well. All things should be pretty self-explanatory.

!!!info ID type
Graphiti cannot diffentiate `String` type from `ID` type by default. Pioneer brought in a custom `ID` struct to tackle this issue.

This custom`ID` can be constructed from any string with its regular initializer or from string literal(s). It can also come from `UUID` and `String` using the extension `.toID()` method.

<sub>It is also hashable so it can also be used as `id` requirement for `Identifiable`</sub>

```swift
import Pioneer

extension User {
    var _id: ID {
        id.toID()
    }

    var _friendIDs: [ID] {
        friendIDs.map { $0.toID() }
    }
}

let schema = try Schema<Void, Resolver> {
    // Add as Scalar type, so Graphiti won't get mad
    ID.asScalar()
    // or
    Scalar(ID.self, as: "ID")
}
```

!!!

### User inputs

We also want an entity for the input that the API client will give to create and/or update a User profile.

```swift
import Pioneer

struct UserInput: Codable {
    var username: String?
    var email: String
    var bio: String
    var friendIDs: [ID]
}

extension User {
    init(id: ID = .uuid(), _ input: UserInput) {
        self.init(
            id: UUID(id.string) ?? UUID(),
            username: input.username,
            email: input.email,
            bio: input.bio,
            friendIDs: input.friendIDs.compactMap { UUID($0) },
        )
    }
}
```

## Datastore

In a real application, you want these `User`(s) to be stored in a persistent database like PostgreSQL or something similar. For this example, we will be simplying the workflow by just building one in memory.

[!ref Fluent FAQ](../../guides/advanced/fluent)

We will be taking advantange of Swift 5.5 `actor` which a structure suitable for cocurrent state management.

```swift
import Pioneer

actor Datastore {
    private var users: [ID: User] = [:]

    func find(with ids: [ID]) async -> [User] {
        ids.compactMap { users[$0] }
    }

    func select() async -> [User] {
        users.values.filter(predicate)
    }

    func insert(_ newUser: User) async -> User {
        users[newUser._id] = newUser
        return newUser
    }

    func update(for id: ID, with newUser: User) async -> User? {
        guard let _ = users[id] else {
            return nil
        }

        users[id] = newUser
        return newUser
    }

    func delete(for id: ID) async -> User? {
        guard let user = users[id] else {
            return nil
        }
        users.removeValue(forKey: id)
        return user
    }

    static let shared: Self = .init()
}
```

This actor should look fairly straightforward.
