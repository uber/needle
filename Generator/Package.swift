// swift-tools-version:5.1
import PackageDescription

// Define the SwiftSyntax release to use based on the version of Swift in use
#if swift(>=5.5) && swift(<5.6)
// Xcode 13.0 / Swift 5.5
let swiftSyntaxVersion: Version = "0.50500.0"
#elseif swift(>=5.4)
// Xcode 12.5 / Swift 5.4
let swiftSyntaxVersion: Version = "0.50400.0"
#elseif swift(>=5.3)
// Xcode 12.0 / Swift 5.3
let swiftSyntaxVersion: Version = "0.50300.0"
#elseif swift(>=5.2)
// Xcode 11.4 / Swift 5.2
let swiftSyntaxVersion: Version = "0.50200.0"
#endif

let package = Package(
    name: "Needle",
    products: [
        .executable(name: "needle", targets: ["needle"]),
        .library(name: "NeedleFramework", targets: ["NeedleFramework"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-tools-support-core", .upToNextMajor(from: "0.1.5")),
        .package(url: "https://github.com/uber/swift-concurrency.git", .upToNextMajor(from: "0.6.5")),
        .package(url: "https://github.com/uber/swift-common.git", .exact("0.5.0")),
        .package(url: "https://github.com/apple/swift-syntax.git", .exact(swiftSyntaxVersion)),
    ],
    targets: [
        .target(
            name: "NeedleFramework",
            dependencies: [
                "SwiftToolsSupport-auto",
                "Concurrency",
                "SourceParsingFramework",
                "SwiftSyntax",
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
    swiftLanguageVersions: [.v5]
)
