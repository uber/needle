load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

http_archive(
    name = "build_bazel_rules_swift",
    sha256 = "a525d254b0323380b7abe7cbbe03534167f0fcb45f44f7d16cdd4d7d057b8f8d",
    url = "https://github.com/bazelbuild/rules_swift/releases/download/0.20.0/rules_swift.0.20.0.tar.gz",
)

load(
    "@build_bazel_rules_swift//swift:repositories.bzl",
    "swift_rules_dependencies",
)

swift_rules_dependencies()

load(
    "@build_bazel_rules_swift//swift:extras.bzl",
    "swift_rules_extra_dependencies",
)

swift_rules_extra_dependencies()
