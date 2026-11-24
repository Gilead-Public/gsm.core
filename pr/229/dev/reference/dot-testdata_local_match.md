# Find a local build matching the installed packages

Scans `root` for builds whose folder name is the
[`fresh_inputs_hash()`](https://gilead-public.github.io/gsm.core/dev/reference/fresh_inputs_hash.md)
of the packages listed in their own snapshot, as installed now. Works
without the test data index (e.g. offline, or before the cache is
redirected).

## Usage

``` r
.testdata_local_match(root = .testdata_local_root())
```

## Arguments

- root:

  `character(1)` Folder holding local builds.

## Value

`character(1)` The matching build folder, or `NULL`.
