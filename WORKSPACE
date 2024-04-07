load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

http_archive(
    name = "build_bazel_rules_apple",
    sha256 = "34c41bfb59cdaea29ac2df5a2fa79e5add609c71bb303b2ebb10985f93fa20e7",
    url = "https://github.com/bazelbuild/rules_apple/releases/download/3.1.1/rules_apple.3.1.1.tar.gz",
)

load(
    "@build_bazel_rules_apple//apple:repositories.bzl",
    "apple_rules_dependencies",
)

apple_rules_dependencies()

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

load(
    "@build_bazel_apple_support//lib:repositories.bzl",
    "apple_support_dependencies",
)

apple_support_dependencies()

SWIFTSYTNAX_VERSION = "509.0.0"

http_archive(
    name = "SwiftSyntax",
    sha256 = "1cddda9f7d249612e3d75d4caa8fd9534c0621b8a890a7d7524a4689bce644f1",
    strip_prefix = "swift-syntax-%s" % SWIFTSYTNAX_VERSION,
    url = "https://github.com/apple/swift-syntax/archive/refs/tags/%s.tar.gz" % SWIFTSYTNAX_VERSION,
)

SWIFT_TOOLS_SUPPORT_CORE_VERSION = "0.5.1"

http_archive(
    name = "SwiftToolsSupportCore",
    build_file_content = """
load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")
objc_library(
    name = "TSCclibc",
    srcs = glob(
        [
            "Sources/TSCclibc/*.c",
        ],
        allow_empty = False,
    ),
    hdrs = [
        "Sources/TSCclibc/include/TSCclibc.h",
        "Sources/TSCclibc/include/indexstore_functions.h",
        "Sources/TSCclibc/include/process.h",
    ],
    module_name = "TSCclibc",
)

swift_library(
    name = "TSCLibc",
    srcs = glob(
        [
            "Sources/TSCLibc/**/*.swift",
        ],
        allow_empty = False,
    ),
    module_name = "TSCLibc",
    deps = [
        ":TSCclibc",
    ],
)

swift_library(
    name = "TSCBasic",
    srcs = glob(
        [
            "Sources/TSCBasic/**/*.swift",
        ],
        allow_empty = False,
    ),
    copts = [
        "-suppress-warnings",
    ],
    module_name = "TSCBasic",
    visibility = ["//visibility:public"],
    deps = [
        ":TSCLibc",
        "@SwiftSystem//:SystemPackage"
    ],
)

swift_library(
    name = "TSCUtility",
    srcs = glob(
        [
            "Sources/TSCUtility/**/*.swift",
        ],
        allow_empty = False,
    ),
    copts = [
        "-suppress-warnings",
    ],
    module_name = "TSCUtility",
    visibility = ["//visibility:public"],
    deps = [
        ":TSCBasic",
    ],
)
    """,
    sha256 = "85ab60d84827ffa01233a766b0d36c6a7aacb0dba0e6304e83ebd1f359504d4d",
    strip_prefix = "swift-tools-support-core-%s" % SWIFT_TOOLS_SUPPORT_CORE_VERSION,
    urls = ["https://github.com/apple/swift-tools-support-core/archive/refs/tags/%s.tar.gz" % SWIFT_TOOLS_SUPPORT_CORE_VERSION],
)

UBER_SWIFT_COMMON_VERSION = "0.5.0"

http_archive(
    name = "UberSwiftCommon",
    build_file_content = """
load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

swift_library(
    name = "CommandFramework",
    srcs = glob(
        [
            "Sources/CommandFramework/**/*.swift",
        ],
        allow_empty = False,
    ),
    copts = ["-suppress-warnings"],
    module_name = "CommandFramework",
    visibility = ["//visibility:public"],
    deps = [
        ":SourceParsingFramework",
        "@SwiftToolsSupportCore//:TSCUtility",
    ],
)

swift_library(
    name = "SourceParsingFramework",
    srcs = glob(
        [
            "Sources/SourceParsingFramework/**/*.swift",
        ],
        allow_empty = False,
    ),
    copts = ["-suppress-warnings"],
    module_name = "SourceParsingFramework",
    visibility = ["//visibility:public"],
    deps = [
        "@SwiftToolsSupportCore//:TSCBasic",
        "@UberSwiftConcurrency//:Concurrency",
    ],
)
    """,
    sha256 = "f4df1d64ee99e7df43079bd49da5fb331d7c4f9556d4852d072e146bce0a7e7e",
    strip_prefix = "swift-common-%s" % UBER_SWIFT_COMMON_VERSION,
    urls = ["https://github.com/uber/swift-common/archive/refs/tags/v%s.tar.gz" % UBER_SWIFT_COMMON_VERSION],
)

UBER_SWIFT_CONCURRENCY_VERSION = "0.7.1"

http_archive(
    name = "UberSwiftConcurrency",
    build_file_content = """
load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

swift_library(
name = "Concurrency",
srcs = glob(
    [
        "Sources/Concurrency/**/*.swift",
    ],
    allow_empty = False,
),
copts = ["-suppress-warnings"],
module_name = "Concurrency",
visibility = ["//visibility:public"],
deps = [
    ":ObjCBridges",
],
)

objc_library(
name = "ObjCBridges",
srcs = glob(
    [
        "Sources/ObjCBridges/*.m",
    ],
    allow_empty = False,
),
hdrs = glob(
    [
        "Sources/ObjCBridges/include/*.h",
    ],
    allow_empty = False,
),
includes = ["Sources/ObjCBridges/include"],
module_name = "ObjCBridges",
)
    """,
    sha256 = "8f95c4e2d4b98f38f14adb53120372d36b7fb54a65ddda1a8f2df3e3ae069ab3",
    strip_prefix = "swift-concurrency-%s" % UBER_SWIFT_CONCURRENCY_VERSION,
    urls = ["https://github.com/uber/swift-concurrency/archive/refs/tags/v%s.tar.gz" % UBER_SWIFT_CONCURRENCY_VERSION],
)

SWIFT_SYSTEM_VERSION = "1.2.1"

http_archive(
    name = "SwiftSystem",
    build_file_content = """
load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

cc_library(
    name = "CSystem",
    srcs = glob(
        ["Sources/CSystem/**/*.c"],
        allow_empty = False
    ),
    hdrs = glob(
        ["Sources/CSystem/include/*.h"],
        allow_empty = False
    ),
)

swift_library(
    name = "SystemPackage",
    module_name = "SystemPackage",
    srcs = glob(
        ["Sources/System/**/*.swift"],
        allow_empty = False
    ),
    defines = [
        "SYSTEM_PACKAGE",
    ],
    deps = [
        ":CSystem",
    ],
    visibility = ["@SwiftToolsSupportCore//:__subpackages__"],
)

    """,
    sha256 = "ab771be8a944893f95eed901be0a81a72ef97add6caa3d0981e61b9b903a987d",
    strip_prefix = "swift-system-%s" % SWIFT_SYSTEM_VERSION,
    url = "https://github.com/apple/swift-system/archive/refs/tags/%s.tar.gz" % SWIFT_SYSTEM_VERSION,
)
