"""Typst toolchains"""

TOOLCHAIN_TYPE = str(Label("//typst:toolchain_type"))

TypstToolchainInfo = provider(
    doc = "Information about how to invoke the typst compiler.",
    fields = {
        "all_files": "depset[File]: All files needed by Typst actions.",
        "compiler": "File: The typst compiler",
        "process_wrapper": "File: The process wrapper for typst actions",
    },
)

def _typst_toolchain_impl(ctx):
    all_files = []
    if DefaultInfo in ctx.attr.compiler:
        all_files.extend([
            ctx.attr.compiler[DefaultInfo].files,
            ctx.attr.compiler[DefaultInfo].default_runfiles.files,
        ])

    if DefaultInfo in ctx.attr._process_wrapper:
        all_files.extend([
            ctx.attr._process_wrapper[DefaultInfo].files,
            ctx.attr._process_wrapper[DefaultInfo].default_runfiles.files,
        ])

    toolchain_info = platform_common.ToolchainInfo(
        typstc_info = TypstToolchainInfo(
            compiler = ctx.file.compiler,
            process_wrapper = ctx.executable._process_wrapper,
            all_files = depset(transitive = all_files),
        ),
    )
    return [toolchain_info]

typst_toolchain = rule(
    doc = "TODO",
    implementation = _typst_toolchain_impl,
    attrs = {
        "compiler": attr.label(
            doc = "TODO",
            allow_single_file = True,
            executable = True,
            mandatory = True,
            cfg = "exec",
        ),
        "_process_wrapper": attr.label(
            cfg = "exec",
            executable = True,
            default = Label("//typst/private/process_wrapper"),
        ),
    },
)
