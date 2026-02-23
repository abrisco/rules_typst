"""rules_typst bzlmod extensions"""

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("@bazel_tools//tools/build_defs/repo:utils.bzl", "maybe")

_HUB_BUILD_CONTENT = """\
{toolchains}
"""

_CONSTRAINTS = {
    "aarch64-apple-darwin": [
        "@platforms//os:macos",
        "@platforms//cpu:aarch64",
    ],
    "aarch64-pc-windows-msvc": [
        "@platforms//os:windows",
        "@platforms//cpu:aarch64",
    ],
    "aarch64-unknown-linux-musl": [
        "@platforms//os:linux",
        "@platforms//cpu:aarch64",
    ],
    "armv7-unknown-linux-musleabi": [
        "@platforms//os:linux",
        "@platforms//cpu:armv7",
    ],
    "riscv64gc-unknown-linux-gnu": [
        "@platforms//os:linux",
        "@platforms//cpu:riscv64",
    ],
    "x86_64-apple-darwin": [
        "@platforms//os:macos",
        "@platforms//cpu:x86_64",
    ],
    "x86_64-pc-windows-msvc": [
        "@platforms//os:windows",
        "@platforms//cpu:x86_64",
    ],
    "x86_64-unknown-linux-musl": [
        "@platforms//os:linux",
        "@platforms//cpu:x86_64",
    ],
}

_VERSIONS = {
    "0.14.2": {
        "aarch64-apple-darwin": {
            "integrity": "sha256-RwqkmiKY0gtlwRmhDk/4gIVQRT4MtNhWJbicrwzt8Eg=",
            "urls": ["https://github.com/typst/typst/releases/download/v0.14.2/typst-aarch64-apple-darwin.tar.xz"],
        },
        "aarch64-pc-windows-msvc": {
            "integrity": "sha256-HEqqDeAAqxeH3aNUw09Pof48JSXT0DjmkqPX2qMz1VE=",
            "urls": ["https://github.com/typst/typst/releases/download/v0.14.2/typst-aarch64-pc-windows-msvc.zip"],
        },
        "aarch64-unknown-linux-musl": {
            "integrity": "sha256-SRsQGqQKOn6oKj+KYjLKu05qfiM4EAguWsgS1D/c1Ho=",
            "urls": ["https://github.com/typst/typst/releases/download/v0.14.2/typst-aarch64-unknown-linux-musl.tar.xz"],
        },
        "armv7-unknown-linux-musleabi": {
            "integrity": "sha256-Vb++revAHCEW8f6mBtzXL+MOHYsC++YdXtd9aMbs4pg=",
            "urls": ["https://github.com/typst/typst/releases/download/v0.14.2/typst-armv7-unknown-linux-musleabi.tar.xz"],
        },
        "riscv64gc-unknown-linux-gnu": {
            "integrity": "sha256-zd06/BS94OWWa/DlZaL4jItpu7mpEedHPU+ilJ5dvBU=",
            "urls": ["https://github.com/typst/typst/releases/download/v0.14.2/typst-riscv64gc-unknown-linux-gnu.tar.xz"],
        },
        "x86_64-apple-darwin": {
            "integrity": "sha256-TpHY4eM6sWT5ScV2LgHuP6pYXIYVoqa9XjZ3+oUGskk=",
            "urls": ["https://github.com/typst/typst/releases/download/v0.14.2/typst-x86_64-apple-darwin.tar.xz"],
        },
        "x86_64-pc-windows-msvc": {
            "integrity": "sha256-UTU5lKyDIYw0lwUuibLEMsU7nUQ5zcGzYeLqR5jr/BM=",
            "urls": ["https://github.com/typst/typst/releases/download/v0.14.2/typst-x86_64-pc-windows-msvc.zip"],
        },
        "x86_64-unknown-linux-musl": {
            "integrity": "sha256-pgRMutKpVN65IRZ+JX4SCsChayAznsARIRlP+dOUmW0=",
            "urls": ["https://github.com/typst/typst/releases/download/v0.14.2/typst-x86_64-unknown-linux-musl.tar.xz"],
        },
    },
}

_TOOLCHAIN_ENTRY = """\
toolchain(
    name = "typst_toolchain_{arch}",
    toolchain_type = "@rules_typst//typst:toolchain_type",
    toolchain = "{toolchain}",
    exec_compatible_with = {constraints},
    visibility = ["//visibility:public"],
)
"""

def _typst_toolchains_hub_impl(repository_ctx):
    toolchains = []
    for toolchain, arch in repository_ctx.attr.toolchains.items():
        toolchains.append(_TOOLCHAIN_ENTRY.format(
            arch = arch,
            constraints = repr(_CONSTRAINTS[arch]),
            toolchain = str(toolchain),
        ))

    repository_ctx.file("BUILD.bazel", _HUB_BUILD_CONTENT.format(
        toolchains = "\n".join(toolchains),
    ))

    repository_ctx.file("WORKSPACE.bazel", """workspace(name = "{}")""".format(
        repository_ctx.name,
    ))

typst_toolchains_hub = repository_rule(
    doc = "A repository rule for defining typst toolchains",
    implementation = _typst_toolchains_hub_impl,
    attrs = {
        "toolchains": attr.label_keyed_string_dict(
            doc = "A mapping of toolchain labels to platforms.",
            mandatory = True,
        ),
    },
)

_TYPST_UNIX_BUILD_CONTENT = """\
load("@rules_typst//typst:typst_toolchain.bzl", "typst_toolchain")

package(default_visibility = ["//visibility:public"])

exports_files(["typst"])

alias(
    name = "{name}",
    actual = "typst",
)

typst_toolchain(
    name = "toolchain",
    compiler = "typst",
)
"""

_TYPST_WINDOWS_BUILD_CONTENT = """\
load("@rules_typst//typst:typst_toolchain.bzl", "typst_toolchain")

package(default_visibility = ["//visibility:public"])

exports_files(["typst.exe"])

alias(
    name = "{name}",
    actual = "typst.exe",
)

typst_toolchain(
    name = "toolchain",
    compiler = "typst.exe",
)
"""

def _typst_impl(module_ctx):
    version = "0.14.2"

    toolchains = {}

    for platform, data in _VERSIONS[version].items():
        name = "typst_{}".format(platform)

        build_file_content = _TYPST_UNIX_BUILD_CONTENT.format(
            name = name,
        )

        # Special case, as it is a zip archive with no prefix to strip.
        if "windows" in platform:
            build_file_content = _TYPST_WINDOWS_BUILD_CONTENT.format(
                name = name,
            )

        maybe(
            http_archive,
            name = name,
            strip_prefix = "typst-{}".format(platform),
            build_file_content = build_file_content,
            integrity = data["integrity"],
            urls = data["urls"],
        )

        toolchains["@{}//:toolchain".format(name)] = platform

    maybe(
        typst_toolchains_hub,
        name = "typst_toolchains",
        toolchains = toolchains,
    )

    return module_ctx.extension_metadata(
        reproducible = True,
    )

typst = module_extension(
    implementation = _typst_impl,
)
