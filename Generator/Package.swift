// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "Needle",
    products: [
        .executable(name: "needle", targets: ["needle"]),
        .library(name: "NeedleFramework", targets: ["NeedleFramework"])
    ],
    dependencies: [
        .package(url: "https://github.com/jpsim/SourceKitten.git", from: "0.20.0"),
        .package(url: "https://github.com/apple/swift-package-manager.git", from: "0.1.0"),
        .package(url: "https://github.com/uber/swift-concurrency.git", from: "0.3.0"),
    ],
    targets: [
        .target(
            name: "needle",
            dependencies: [
                "NeedleFramework",
            ]),
        .target(
            name: "NeedleFramework",
            dependencies: [
                "Utility",
                "SourceKittenFramework",
                "Concurrency",
            ]),
        .testTarget(
            name: "NeedleFrameworkTests",
            dependencies: ["NeedleFramework"],
            exclude: [
                "Fixtures",
            ]),
    ],
    swiftLanguageVersions: [4]
)
