// swift-tools-version:5.10
import PackageDescription

let package = Package(
    name: "Needle",
    platforms: [
          .macOS(.v10_15)
    ],
    products: [
        .executable(name: "needle", targets: ["needle"]),
        .library(name: "NeedleFramework", targets: ["NeedleFramework"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-tools-support-core", exact: "0.2.7"),
        .package(url: "https://github.com/uber/swift-concurrency.git", .upToNextMajor(from: "0.6.5")),
        .package(url: "https://github.com/uber/swift-common.git", exact: "0.5.0"),
        .package(url: "https://github.com/apple/swift-syntax.git", .upToNextMajor(from: "510.0.0")),
    ],
    targets: [
        .target(
            name: "NeedleFramework",
            dependencies: [
                .product(name: "SwiftToolsSupport-auto", package: "swift-tools-support-core"),
                .product(name: "Concurrency", package: "swift-concurrency"),
                .product(name: "SourceParsingFramework", package: "swift-common"),
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftParser", package: "swift-syntax"),
            ]),
        .testTarget(
            name: "NeedleFrameworkTests",
            dependencies: ["NeedleFramework"],
            exclude: [
                "Fixtures",
            ]),
        .executableTarget(
            name: "needle",
            dependencies: [
                "NeedleFramework",
                .product(name: "CommandFramework", package: "swift-common")
            ]),
    ],
    swiftLanguageVersions: [.v5]
)
