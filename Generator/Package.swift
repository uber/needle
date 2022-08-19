// swift-tools-version:5.1
import PackageDescription

// Based on https://github.com/apple/swift-syntax#readme
#if swift(>=5.6) && swift(<5.7)
let swiftSyntaxVersion: Version = "0.50600.1"
#elseif swift(>=5.5)
let swiftSyntaxVersion: Version = "0.50500.0"
#elseif swift(>=5.4)
let swiftSyntaxVersion: Version = "0.50400.0"
#elseif swift(>=5.3)
let swiftSyntaxVersion: Version = "0.50300.0"
#elseif swift(>=5.2)
let swiftSyntaxVersion: Version = "0.50200.0"
#endif

var needleDependencies: Array<Target.Dependency> = [
    .product(name: "SwiftToolsSupport-auto", package: "swift-tools-support-core"),
    .product(name: "Concurrency", package: "swift-concurrency"),
    .product(name: "SourceParsingFramework", package: "swift-common"),
    .product(name: "SwiftSyntax", package: "swift-syntax"),
]
#if swift(>=5.6)
needleDependencies.append(.product(name: "SwiftSyntaxParser", package: "swift-syntax"))
#endif

let package = Package(
    name: "Needle",
    products: [
        .executable(name: "needle", targets: ["needle"]),
        .library(name: "NeedleFramework", targets: ["NeedleFramework"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-tools-support-core", .exact("0.2.5")),
        .package(url: "https://github.com/uber/swift-concurrency.git", .upToNextMajor(from: "0.6.5")),
        .package(url: "https://github.com/uber/swift-common.git", .exact("0.5.0")),
        .package(url: "https://github.com/apple/swift-syntax.git", .exact(swiftSyntaxVersion)),
    ],
    targets: [
        .target(
            name: "NeedleFramework",
            dependencies: needleDependencies
            ),
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
