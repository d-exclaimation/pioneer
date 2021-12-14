---
icon: telescope
order: 70
---

# Schema

This section are going to be specific to the GraphQL schema library you are using. In this case, we are using Graphiti and the most part Pioneer has no impact on the schema building process beside adding a few extensions to existing data structures.

I am going to ignore the error handling portion and assume the schema will be constructed with no errors. Obviously, feel free to customize this and add your error handling logic if necessary

## Graphiti

```swift
import Pioneer
import Graphiti

let schema = try? Schema<Resolver, Context> {
    Scalar(ID.self)

    Type(User.self) {
        Field("id", at: \.id)
        Field("username", at: \.username)
        Field("email", at: \.email)
        Field("bio", at: \.bio)

        // Computed properties
        Field("displayName", at: \.displayName)

        // Computed properties with custom resolver (for relationship)
        Field("friends", at: \.friends)
    }

    Input(UserInput.self) {
        InputField("username", at: \.username)
        InputField("email", at: \.email)

        // Default value from GrapHQL
        InputField("bio", at: \.bio)
            .defaultValue("")

        // Same here
        InputField("friendIDs", at: \.friendIDs)
            .defaultValue([])
    }

    Query {
        Field("users", at: Resolver.users)
        Field("user", at: Resolver.user) {
            Argument("id", at: \.id)
        }
    }

    Mutation {
        Field("create", at: Resolver.create) {
            Argument("user", at: \.user)
        }
        Field("update", at: Resolver.update) {
            Argument("id", at: \.id)
            Argument("user", at: \.user)
        }
        Field("delete", at: Resolver.delete) {
            Argument("id", at: \.id)
        }
    }

    Subscription {
        // Subscription field using the EventStream
        SubscriptionField("onChange", as: User.self, atSub: Resolver.onChange)
    }
}
```

==- Equivalent in GraphQL SDL

```graphql
type User {
  id: ID!
  username: String
  email: String!
  bio: String!
  displayName: String!
  friends: [User!]!
}

input UserInput {
  username: String
  email: String!
  bio: String! = ""
  friendIDs: [ID!]! = []
}

type Query {
  users: [User!]!
  user(id: ID!): User
}

type Mutation {
  create(user: UserInput!): User!
  update(id: ID!, user: UserInput!): User
  delete(id: ID!): User
}

type Subscription {
  onChange: User!
}
```

===
