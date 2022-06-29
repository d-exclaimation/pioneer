---
icon: tools
order: 100
---

# Setup

In this guide, we will be using [Graphiti](https://github.com/GraphQLSwift/Graphiti) and setting up Vapor from scratch without using any template.

## Prerequisites

Obviously, Pioneer requires Swift installed. Swift can be installed for most operation systems, just follow the official guide from [swift.org](https://www.swift.org/download/)

| Platform | Toolchain                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            |
| -------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| MacOS    | [!badge target="blank" text="Xcode 13.2"](https://download.swift.org/swift-5.5.2-release/xcode/swift-5.5.2-RELEASE/swift-5.5.2-RELEASE-osx.pkg)                                                                                                                                                                                                                                                                                                                                                                      |
| Ubuntu   | [!badge target="blank" variant="warning" text="16.04"](https://download.swift.org/swift-5.5.2-release/ubuntu1604/swift-5.5.2-RELEASE/swift-5.5.2-RELEASE-ubuntu16.04.tar.gz) [!badge target="blank" variant="success" text="18.04"](https://download.swift.org/swift-5.5.2-release/ubuntu1804/swift-5.5.2-RELEASE/swift-5.5.2-RELEASE-ubuntu18.04.tar.gz) [!badge target="blank" text="20.04"](https://download.swift.org/swift-5.5.2-release/ubuntu2004/swift-5.5.2-RELEASE/swift-5.5.2-RELEASE-ubuntu20.04.tar.gz) |
| Windows  | [!badge target="blank" text="Windows 10"](https://download.swift.org/swift-5.5.2-release/windows10/swift-5.5.2-RELEASE/swift-5.5.2-RELEASE-windows10.exe)                                                                                                                                                                                                                                                                                                                                                            |

## Application

Setup the skeleton of the executable using Swift package manager by running:

```bash
swift package init --type executable
```

## Dependencies

Next, add all three main dependencies: Vapor, Graphiti and of course, Pioneer to your `Package.swift`.

```swift Package.swift
import PackageDescription

let package = Package(
    dependencies: [
        .package(url: "https://github.com/GraphQLSwift/Graphiti.git", from: "1.0.0"),
        .package(url: "https://github.com/vapor/vapor.git", from: "4.61.1"),
        .package(url: "https://github.com/d-exclaimation/pioneer", from: "0.8.4")
    ],
    targets: [
        .target(
            name: "...",
            dependencies: [
                .product(name: "Pioneer", package: "pioneer"),
                .product(name: "Graphiti", package: "Graphiti"),
                .product(name: "Vapor", package: "vapor")
            ]
        )
    ]
)
```

!!!warning Swift 5.5 toolchain
Pioneer require Swift 5.5 or up due to the `_Concurrency` package and features it relies on.

```swift Specifying requirement for Swift 5.5
let package = Package(
    platforms: [
        .macOS(.v12)
    ],
)
```

At least until Xcode 13.2 is fully fleshed out, where these features are being brought to older versions as well.

!!!

## Basic application

Let's continue with setting up the basic Vapor application.

Go to your `main.swift`, add Vapor, and setup a simple Vapor application with no routing or any other configuration.

```swift main.swift
import Vapor

let app = try Application(.detect())

defer {
    app.shutdown()
}

try app.run()
```
