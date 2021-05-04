load("@build_bazel_rules_swift//swift:swift.bzl",
    "swift_library",
    "swift_test"
)

swift_test(
    name = "Tests",
    deps = [
        ":NeedleFoundationTest"
    ]
)

swift_library(
    name = "NeedleFoundationTest",
    module_name = "NeedleFoundationTest",
    deps = [
        "//:NeedleFoundation"
    ],
    srcs = glob([
        "*.swift",
        "Pluginized/*.swift"
    ], allow_empty = False),
    visibility = ["//Tests:__subpackages__"]
)
