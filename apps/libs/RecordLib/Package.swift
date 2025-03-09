// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "RecordLib",
    platforms: [
        .macOS(.v14), .iOS(.v16), .tvOS(.v16)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "RecordLib",
            targets: ["RecordLib"]),
    ],
    dependencies: [
        .package(url: "file:///Volumes/Projects/Evidently/Blackbird", revision: "e1d791301196406574cd148d46969b6565bb2e87"),
        // .package(url: "https://github.com/thepia/Blackbird", from: "0.5.1"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "RecordLib",
            dependencies: ["Blackbird"]),
        .testTarget(
            name: "RecordLibTests",
            dependencies: ["Blackbird", "RecordLib"]),
    ],
    swiftLanguageVersions: [.v5]
)
