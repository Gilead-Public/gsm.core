# Run the builder into a local build folder

Builds into a temporary sibling folder, then replaces `dir`, so a failed
build leaves any previous one intact.

## Usage

``` r
.testdata_local_build(dir, builder)
```

## Arguments

- dir:

  `character(1)` The build folder.

- builder:

  `function` From
  [`.testdata_builder()`](https://gilead-public.github.io/gsm.core/dev/reference/dot-testdata_builder.md).

## Value

`dir`, invisibly.
