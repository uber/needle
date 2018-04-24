// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "NeedleFramework",
    products: [
        .library(
            name: "NeedleFramework",
            targets: ["NeedleFramework"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "NeedleFramework",
            dependencies: []),
        .testTarget(
            name: "NeedleFrameworkTests",
            dependencies: ["NeedleFramework"]),
    ],
    swiftLanguageVersions: [4]
)
