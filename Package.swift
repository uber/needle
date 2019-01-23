// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "NeedleFoundation",
    products: [
        .library(name: "NeedleFoundation", targets: ["NeedleFoundation"])
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
    ],
    swiftLanguageVersions: [4]
)
