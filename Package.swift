// swift-tools-version:5.5.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Pioneer",
    platforms: [
        .macOS(.v10_15),
    ],
    products: [
        .library(
            name: "Pioneer",
            targets: ["Pioneer"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/GraphQLSwift/GraphQL.git", from: "2.10.3"),
        .package(url: "https://github.com/GraphQLSwift/Graphiti.git", from: "1.15.1"),
        .package(url: "https://github.com/vapor/vapor.git", from: "4.106.3"),
    ],
    targets: [
        .target(
            name: "Pioneer",
            dependencies: [
                "GraphQL", "Graphiti",
                .product(name: "Vapor", package: "vapor"),
            ]
        ),
        .testTarget(
            name: "PioneerTests",
            dependencies: [
                "Pioneer",
                .product(name: "XCTVapor", package: "vapor"),
            ]
        ),
    ]
)
