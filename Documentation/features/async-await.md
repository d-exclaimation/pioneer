---
icon: paper-airplane
order: 100
---

# Async / Await

Pioneer is built for Swift 5.5 and up, which utilies heavily the new concurrency features of Swift. One of the most common one is `async/await` as replacement for using something like callback and `EventLoopFuture` from Swift-NIO.

## Async resolver

If you are using Graphiti `v1.1` and up, Graphiti should now support `async/await` for resolvers, but Pioneer still add some useful ones to help brigde between Swift-NIO and `async/await`.

!!!info Async await extensions
If you are using Graphiti `v1.1` or later, make sure Pioneer is up to date as it will prevent any ambiguity.

If you are using Graphiti before `v1.1` which hasn't added async await support, make sure Pioneer is in the version before `v0.9.3` to get those async await from Pioneer.
!!!

You can write your resolver function with `async/await` whether it is throwing or non-throwing, whether is a regular field resolver or even subscription resolver.

```swift
struct Resolver {
    func asyncNonThrowing(_: Context, _: NoArgs) async -> Any {
        ...
    }

    func asyncThrowing(_: Context, _: NoArgs) async throws -> Any {
        ...
    }

    func asyncSubscription(_: Context, _: NoArgs) async -> EventStream<Any> {
        ...
    }
}


try? Schema<Resolver, Context> {
    Query {
        Field("field1", at: Resolver.asyncNonThrowing)
        Field("field2", at: Resolver.asyncThrowing)
    }
    Subscription {
        Field("field3", as: Any.self, atSub: Resolver.asyncSubscription)
    }
}

```

## Limitations

Given that both Vapor and Graphiti is still heavily use SwiftNIO, `async/await` extensions are just bridges and it's still best to know how to use SwiftNIO `EventLoopGroup`, `EventLoopFuture`, and `EventLoopPromise`.

You can easily create your own bridge by using `EventLoopPromise`'s `completeWithTask` method.

```swift
import NIO

let promise = eventLoop.makePromise(of: String.self)

promise.completeWithTask {
    await someOperation()
    return "Done!!"
}

let future: EventLoopFuture<String> = promise.futureResult
```

This is a very common logic and you can definitely make an extension to automatically set this up.

```swift
#if compiler(>=5.5.2) && canImport(_Concurrency)
import NIO

extension EventLoop {
    @available(macOS 10.15, iOS 13, tvOS 13, watchOS 6, *)
    func makeFutureWithTask<Value>(_ body: @Sendable @escaping () async throws -> Value) -> EventLoopFuture<Value> {
        let promise = eventLoop.makePromise(of: Value.self)
        promise.completeWithTask(body)
        return promise.futureResult
    }
}

#endif
```

### Getting EventLoop

There are a lot of cases where briding between NIO EventLoopFuture to `async/await` still need access to the `EventLoop` object. There are a couple approached to acquiring the `EventLoop` object.

One of them is accessing from either the Vapor `Application` or `Request`. In this scenario, you can pass them in through the context builder and access them as part of the context in your resolvers.

```swift
Pioneer(
    ...,
    contextBuilder: { req, _ in
        let ev = req.eventLoop // <- Access here
        return Context(eventLoop: ev)
    }
)

struct Resolver {
    func asyncResolver(ctx: Context, _: NoArgs) async -> Any {
        await doSomething(with: ctx.eventLoop)
    }
}
```

Another approach is by having a resolver that takes a 3rd parameter of the `EventLoopGroup` itself.

```swift
struct Resolver {
    ...

    func asyncResolverWithEventLoop(_: Void, _: NoArgs, eventLoop: EventLoopGroup) async -> Any {
        await doSomething(with: eventLoop)
    }
}
```
