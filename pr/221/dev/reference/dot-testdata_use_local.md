# Use (building if needed) the local build for the installed packages

Use (building if needed) the local build for the installed packages

## Usage

``` r
.testdata_use_local(
  state,
  packages,
  installed,
  builder = .testdata_builder(),
  rebuild = FALSE
)
```

## Arguments

- state:

  `FreshState` The checker's state store.

- packages:

  `character` The indexed package names.

- installed:

  `list` Output of
  [`package_versions()`](https://gilead-public.github.io/gsm.core/dev/reference/package_versions.md)
  for `packages`.

- builder:

  `function` From
  [`.testdata_builder()`](https://gilead-public.github.io/gsm.core/dev/reference/dot-testdata_builder.md).

- rebuild:

  `logical(1)` Build even if a build exists?

## Value

`character(1)` The tag to use (`data-<fp12>`).
