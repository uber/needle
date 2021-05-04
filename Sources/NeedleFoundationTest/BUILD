load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

swift_library(
    name = "NeedleFoundationTest",
    module_name = "NeedleFoundationTest",
    deps = [
        "//:NeedleFoundation"
    ],
    srcs = [
        "MockComponentPathBuilder.swift"
    ],
    visibility = ["//Tests:__subpackages__"]
)
