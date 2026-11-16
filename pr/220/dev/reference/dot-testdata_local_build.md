# Run the builder into a local build folder

Builds into a temporary sibling folder, then replaces `dir`, so a failed
build leaves any previous one intact. Concurrent sessions don't lock
each other out: if another session finishes the same automatic build
first, its result is kept, and the swap never leaves `dir` missing while
it's in use.

## Usage

``` r
.testdata_local_build(dir, builder, rebuild = FALSE)
```

## Arguments

- dir:

  `character(1)` The build folder.

- builder:

  `function` From
  [`.testdata_builder()`](https://gilead-public.github.io/gsm.core/dev/reference/dot-testdata_builder.md).

- rebuild:

  `logical(1)` Build even if a build exists?

## Value

`dir`, invisibly.
