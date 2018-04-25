// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "Needle",
    products: [
        .executable(name: "needle", targets: ["Needle"])
    ],
    dependencies: [
        .package(url: "https://github.com/jpsim/SourceKitten.git", from: "0.20.0"),
        .package(url: "https://github.com/apple/swift-package-manager.git", from: "0.1.0"),
    ],
    targets: [
        .target(
            name: "Needle",
            dependencies: [
                "Utility",
                "SourceKittenFramework",
            ]
        )
    ],
    swiftLanguageVersions: [4]
)
