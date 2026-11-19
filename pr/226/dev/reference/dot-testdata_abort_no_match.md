# Error for an installed package with no matching build

Error for an installed package with no matching build

## Usage

``` r
.testdata_abort_no_match(pkg, version, sha)
```

## Arguments

- pkg:

  `character(1)` The package that removed the last build.

- version:

  `character(1)` Its installed version.

- sha:

  `character(1)` Its installed `RemoteSha`, or `NA`.

## Value

Nothing; errors with class `gsm_testdata_no_match`.
