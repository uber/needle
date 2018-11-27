// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "NeedleTools",
    products: [
        .executable(name: "needletools", targets: ["needletools"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-package-manager.git", from: "0.1.0"),
        .package(url: "https://github.com/uber/swift-concurrency.git", from: "0.6.1"),
    ],
    targets: [
        .target(
            name: "needletools",
            dependencies: [
                "Concurrency",
                "Utility",
            ]),
    ],
    swiftLanguageVersions: [4]
)
