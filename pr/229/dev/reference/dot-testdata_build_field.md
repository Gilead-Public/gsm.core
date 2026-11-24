# One package field for every build

One package field for every build

## Usage

``` r
.testdata_build_field(builds, pkg, field)
```

## Arguments

- builds:

  `data.frame` `index$builds` from
  [`.testdata_parse_index()`](https://gilead-public.github.io/gsm.core/dev/reference/dot-testdata_parse_index.md).

- pkg:

  `character(1)` The package that removed the last build.

- field:

  `character(1)` `"version"` or `"remote_sha"`.

## Value

`character` One value per build (`NA` if missing).
