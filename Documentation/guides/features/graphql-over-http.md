---
icon: file-binary
order: 80
---

# GraphQL Over HTTP

GraphQL spec define how a GraphQL operation through HTTP. The spec specify that operations can be done through either **GET** and **POST** request. Both of these are supported by Pioneer.

## HTTP Strategy

Pioneer have a feature to specify how operations can be handled through HTTP. There are situations where a GraphQL API should not perform something like mutations through HTTP **GET**, or the user of the library preffered just using HTTP **POST** for all operations (excluding subscriptions).

`HTTPStrategy` is a enum that can be passed in as one of the arguments when initializing Pioneer to specify which approach you prefer.

| HTTPStrategy             | GET                                                                                | POST                                                                               |
| ------------------------ | ---------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------- |
| `onlyPost`               | -                                                                                  | [!badge variant="success" text="Query"] [!badge variant="warning" text="Mutation"] |
| `onlyGet`                | [!badge variant="success" text="Query"] [!badge variant="warning" text="Mutation"] | -                                                                                  |
| `queryOnlyGet` (default) | [!badge variant="success" text="Query"]                                            | [!badge variant="success" text="Query"] [!badge variant="warning" text="Mutation"] |
| `mutationOnlyPost`       | [!badge variant="success" text="Query"] [!badge variant="warning" text="Mutation"] | [!badge variant="warning" text="Mutation"]                                         |
| `splitQueryAndMutation`  | [!badge variant="success" text="Query"]                                            | [!badge variant="warning" text="Mutation"]                                         |
| `both`                   | [!badge variant="success" text="Query"] [!badge variant="warning" text="Mutation"] | [!badge variant="success" text="Query"] [!badge variant="warning" text="Mutation"] |
