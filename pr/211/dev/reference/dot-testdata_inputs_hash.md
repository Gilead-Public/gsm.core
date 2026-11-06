# Hash of the packages that built a bundle

Must match `gsm.datasim:::.inputs_hash()`: SHA-256 of one
`"<package> <version> <remote_sha>"` line per package (missing SHA as
`NA`), sorted by name in C-locale order and joined with `"\n"`.

## Usage

``` r
.testdata_inputs_hash(packages)
```

## Arguments

- packages:

  `list` Named by package; each element has `version` and `remote_sha`,
  as from
  [`package_versions()`](https://gilead-public.github.io/gsm.core/dev/reference/package_versions.md).

## Value

`character(1)` A 64-character hex string.
