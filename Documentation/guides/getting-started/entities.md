---
icon: people
order: 90
---

# Entities

Continuing from the setup, now we will be declaring entities for the GraphQL API.

Let's say for this example, we will have a user management system where the API can be used to create, find, update, and delete user profile(s).

## User profiles

Declaring the `User` model is fairly straight forward.

```swift User.swift
struct User: Identifiable, Codable {
    var id: String
    var username: String?
    var email: String
    var bio: String

    var displayName: String {
        username ?? email
    }

    var friendIDs: [String]
}
```

Here, we have a couple properties and some computed ones as well. All things should be pretty self-explanatory.

!!!info ID type
Graphiti cannot diffentiate `String` type from `ID` type by default. Pioneer has a custom `ID` struct built in that can be used as GraphQL's `ID`.

You can easy add the custom `ID` which can be constructed from any string and string literals (it is hashable so it can also be used as `id` requirement for `Identifiable`).

```swift
import Pioneer

struct User: Identifiable, Codable {
    var id: ID = "..."
    var friendIDs: [ID] = []
}

let schema = try Schema<Void, Resolver> {
    // Add as Scalar type, so Graphiti won't get mad
    ID.asScalar()
    // or
    Scalr(ID.self, as: "ID")
}
```

!!!

### User inputs

We also want a entity for the input that the API client will give to create and/or update a User profile.

```swift
import Pioneer

struct UserInput: Codable {
    var username: String?
    var email: String
    var bio: String
    var friendIDs: [ID]
}

extension User {
    init(_ input: UserInput) {
        self.init(
            id: .uuid(), // <- ID type from a generated UUID string
            username: input.username,
            email: input.email,
            bio: input.bio,
            friendIDs: input.friendIDs,
        )
    }
}
```

## In memory datastore

In a real application, you want this `User` to be stored in a persistent database like PostgreSQL or something similar. For this example, we will be simplying the workflow by just building one in code that's also not persistent.

We will be taking advantange of Swift 5.5 `actor` which a database suitable for handling state management in a concurrent application.

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
        users[newUser.id] = newUser
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
