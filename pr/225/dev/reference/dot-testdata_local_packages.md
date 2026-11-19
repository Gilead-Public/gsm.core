# Package names a local build was keyed by

Read from `inputs.json`, written when the build is first used, falling
back to the packages in `snapshot.json` (optional for builders).

## Usage

``` r
.testdata_local_packages(dir)
```

## Arguments

- dir:

  `character(1)` The build folder.

## Value

`character` Package names; empty if unknown.
