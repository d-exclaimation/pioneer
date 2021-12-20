---
icon: package
order: 80
---

# Structs and Classes

## ID

The ID scalar type represents a unique identifier, often used to refetch an object or as the key for a cache.

!!!success String literals and extensions

You can convert a string to `ID` easily either using the initializer direct or using the `.id` computed properties added to all Strings.

```swift
let id: ID = "my-id".id
let id: ID = .init("my-id")
let id: ID = "my-id"
```

String literals can be implicitly transform to `ID`

!!!

The ID type is serialized in the same way as a String; however, defining it as an ID signifies that it is not intended to be human‐readable.

### `init`

Returns a new [ID](#id) from a string.

+++ Example

```swift
let id = ID("any-string")
```

+++ Options

| Name | Type                                     | Description                              |
| ---- | ---------------------------------------- | ---------------------------------------- |
| \_   | [!badge variant="primary" text="String"] | String value to which the ID is built on |

+++

### `description`

Returns the string value to satify `CustomStringConvertible` protocol.

### `count`

Returns the length of the string value from this [ID](#id).

### `string`

A getter for the string value.

### `uuid` (static)

A static initializer function to create a new [ID](#id) from a newly generated UUID.

+++ Example

```swift
let uuid: ID = .uuid()
```

+++

### `random` (static)

A static initializer function to create a new [ID](#id) from a random set of characters up to the specified length.

!!!warning Uniqueness

Random ID does not guarantee uniqueness, for that recommended to use [`.uuid()`](#uuid-static) instead.

!!!

+++ Example

```swift
let randoID: ID = .random(length: 25)
```

+++ Options

| Name     | Type                                  | Description                  |
| -------- | ------------------------------------- | ---------------------------- |
| `length` | [!badge variant="primary" text="Int"] | Length for the randomized ID |

+++

## GraphQLMessage

Generic\* GraphQL Websocket Message according to all sub-protocol.

_\*Generic means most of the messages, there are some exceptions_

### `init`

Returns a new instance by specifying all the parameters of using default if not given one.

+++ Example

```swift
let message = GraphQLMessage(
    id: "1",
    type: "next",
    payload: [
        "data": [...]
    ]
)
```

+++ Options

| Name      | Type                                             | Description                                     |
| --------- | ------------------------------------------------ | ----------------------------------------------- |
| `type`    | [!badge String]                                  | Message type specified to allow differentiation |
| `id`      | [!badge variant="warning" text="String?"]        | Operation based ID if any                       |
| `payload` | [!badge variant="warning" text="[String: Map]?"] | Any payload in terms of object form             |

+++

### `from`

Returns an instance using [GraphQLRequest](#graphqlrequest).

+++ Example

```swift
let message = GraphQLMessage.from(
    type: "next",
    id: "1",
    GraphQLRequest(...)
)
```

+++ Options

| Name   | Type                                             | Description                                     |
| ------ | ------------------------------------------------ | ----------------------------------------------- |
| `type` | [!badge String]                                  | Message type specified to allow differentiation |
| `id`   | [!badge variant="warning" text="String?"]        | Operation based ID if any                       |
| \_     | [!badge variant="warning" text="GraphQLRequest"] | GraphQLRequest used                             |

+++

## GraphQLRequest

GraphQL Request according to the spec.

!!!success Custom decoding
This struct is useful when parsing your own GraphQL request, it can also easily detect whether that request is an introspection, or find out what type of operation is being ran.
!!!

### `init`

Returns a new instance by specifying all the parameters of using default if not given one.

+++ Example

```swift
let message = GraphQLRequest(
    query: "query { me { id, name } }",
    operationName: nil,
    variables: nil
)
```

+++ Options

| Name            | Type                                             | Description                                                   |
| --------------- | ------------------------------------------------ | ------------------------------------------------------------- |
| `query`         | [!badge String]                                  | GraphQL request query string                                  |
| `operationName` | [!badge variant="warning" text="String?"]        | Name of operation being request from the query string         |
| `variables`     | [!badge variant="warning" text="[String: Map]?"] | Any payload brought to fill the variables in the query string |

+++

### `operationType`

Returning the parsed `operationType` of this request.

+++ Example

```swift
let message: GraphQLRequest

switch try message.operationType() {
case .subscription:
    // ...
case .query:
    // ...
case .mutation:
    // ...
}
```

+++

### `isIntrospection`

Return true if the request is valid, is a query operation, is querying the schema information whether the entire schema types or each individual types.

+++ Example

```swift
let message: GraphQLRequest

guard !message.isIntrospection else {
    // do something with introspection
}

// Must not be introspection
```

+++
