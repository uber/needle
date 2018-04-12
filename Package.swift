// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "Needle",
    products: [
        .executable(name: "needle", targets: ["needle"])
    ],
    dependencies: [
        .package(url: "https://github.com/jpsim/SourceKitten.git", from: "0.20.0"),
    ],
    targets: [
        .target(
            name: "needle",
            dependencies: [
                "SourceKittenFramework",
            ]
        )
    ],
    swiftLanguageVersions: [4]
)
