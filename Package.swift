// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Pioneer",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "Pioneer",
            targets: ["Pioneer"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(url: "https://github.com/GraphQLSwift/GraphQL.git", from: "2.4.0"),
        .package(url: "https://github.com/GraphQLSwift/Graphiti.git", from: "1.2.1"),
        .package(url: "https://github.com/vapor/vapor.git", from: "4.67.1")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "Pioneer",
            dependencies: [
                "GraphQL", "Graphiti",
                .product(name: "Vapor", package: "vapor")
            ]),
        .testTarget(
            name: "PioneerTests",
            dependencies: [
                "Pioneer",
                 .product(name: "XCTVapor", package: "vapor")
            ]),
    ]
)
