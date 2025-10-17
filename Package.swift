// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MinimalTCA",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "MinimalTCA",
            targets: ["MinimalTCA"]),
    ],
    dependencies: [
      .package(url: "https://source.skip.tools/skip.git", from: "1.6.17"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
          name: "MinimalTCA",
          plugins: [
            .plugin(name: "skipstone", package: "skip")
          ]),
        .testTarget(
            name: "MinimalTCATests",
            dependencies: ["MinimalTCA"]
        ),
    ]
)
