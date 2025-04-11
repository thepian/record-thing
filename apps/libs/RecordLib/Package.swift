// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "RecordLib",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14), .iOS(.v17), .tvOS(.v17)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "RecordLib",
            targets: ["RecordLib"]),
    ],
    dependencies: [
        .package(url: "https://github.com/siteline/swiftui-introspect", from: "1.3.0"),
//        .package(url: "file:///Volumes/Projects/Evidently/Blackbird", revision: "e1d791301196406574cd148d46969b6565bb2e87"),
         .package(url: "https://github.com/thepia/Blackbird", from: "0.5.1"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "RecordLib",
            dependencies: [
                .product(name: "Blackbird", package: "Blackbird"),
                .product(name: "SwiftUIIntrospect", package: "swiftui-introspect")
            ],
            resources: [
                .process("Resources") // This line adds the Resources directory
            ]),
        .testTarget(
            name: "RecordLibTests",
            dependencies: [
                .product(name: "Blackbird", package: "Blackbird"),
                .product(name: "SwiftUIIntrospect", package: "swiftui-introspect"),
                "RecordLib"
            ]),
    ],
    swiftLanguageVersions: [.v5]
)
