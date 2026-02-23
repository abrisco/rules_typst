"""Typst rules"""

load(":providers.bzl", "TypstInfo")
load(":toolchain.bzl", "TOOLCHAIN_TYPE")

def _rlocationpath(file, workspace_name):
    if file.short_path.startswith("../"):
        return file.short_path[len("../"):]

    return "{}/{}".format(workspace_name, file.short_path)

def _typst_impl(ctx):
    """Implementation of the typst rule."""

    toolchain_info = ctx.toolchains[TOOLCHAIN_TYPE].typstc_info

    # Declare pdf output file.
    pdf_outfile = ctx.actions.declare_file("{}.pdf".format(ctx.label.name))

    args = ctx.actions.args()
    args.add(toolchain_info.compiler, format = "--compiler=%s")
    args.add(pdf_outfile, format = "--out=%s")
    args.add("--src={}={}".format(
        ctx.file.src.path,
        _rlocationpath(ctx.file.src, ctx.workspace_name),
    ))

    # Track all inputs with their runfiles paths to ensure generated sources
    # are placed to their appropriate relative paths.
    for src in ctx.files.data:
        args.add("--input={}={}".format(
            src.path,
            _rlocationpath(src, ctx.workspace_name),
        ))

    ctx.actions.run(
        mnemonic = "TypstC",
        executable = toolchain_info.process_wrapper,
        arguments = [args],
        outputs = [pdf_outfile],
        tools = toolchain_info.all_files,
        inputs = depset([ctx.file.src] + ctx.files.data),
    )

    return [
        DefaultInfo(files = depset([pdf_outfile])),
        TypstInfo(),
    ]

typst = rule(
    doc = "TODO",
    implementation = _typst_impl,
    attrs = {
        "data": attr.label_list(
            doc = "TODO",
            allow_files = True,
            mandatory = False,
        ),
        "src": attr.label(
            doc = "TODO",
            allow_single_file = [".typ"],
            mandatory = True,
        ),
    },
    toolchains = [TOOLCHAIN_TYPE],
)
