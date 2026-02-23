# rules_typst

Bazel rules for [Typst](https://typst.app/).

## Development

### Pre-commit hooks

This repo uses [pre-commit](https://pre-commit.com/) to run [buildifier](https://github.com/bazelbuild/buildtools/tree/master/buildifier) for formatting and linting Bazel files.

```sh
pip install pre-commit
pre-commit install
```

To manually run against all files:

```sh
pre-commit run --all-files
```
