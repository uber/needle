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
        .package(url: "https://github.com/uber/swift-concurrency.git", .upToNextMajor(from: "0.6.5")),
    ],
    targets: [
        .target(
            name: "SourceParsingFramework",
            dependencies: [
                "Utility",
                "Concurrency",
                "SourceKittenFramework",
            ]),
        .testTarget(
            name: "SourceParsingFrameworkTests",
            dependencies: ["SourceParsingFramework"],
            exclude: [
                "Fixtures",
            ]),
        .target(
            name: "CommandFramework",
            dependencies: [
                "Utility",
                "SourceParsingFramework",
            ]),
        .target(
            name: "NeedleFramework",
            dependencies: [
                "Utility",
                "SourceKittenFramework",
                "Concurrency",
                "SourceParsingFramework",
            ]),
        .testTarget(
            name: "NeedleFrameworkTests",
            dependencies: ["NeedleFramework"],
            exclude: [
                "Fixtures",
            ]),
        .target(
            name: "needle",
            dependencies: [
                "NeedleFramework",
                "CommandFramework",
            ]),
    ],
    swiftLanguageVersions: [4]
)
