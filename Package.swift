// swift-tools-version:5.1
import PackageDescription

let package = Package(
    name: "NeedleFoundation",
    products: [
        .library(name: "NeedleFoundation", targets: ["NeedleFoundation"]),
        .library(name: "NeedleFoundationTest", targets: ["NeedleFoundationTest"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "NeedleFoundation",
            dependencies: []),
        .testTarget(
            name: "NeedleFoundationTests",
            dependencies: ["NeedleFoundation"],
            exclude: []),
        .target(
            name: "NeedleFoundationTest",
            dependencies: ["NeedleFoundation"]),
        .testTarget(
            name: "NeedleFoundationTestTests",
            dependencies: ["NeedleFoundationTest"],
            exclude: []),
    ],
    swiftLanguageVersions: [.v5]
)
