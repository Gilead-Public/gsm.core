# Warn that test data fell back to the last release

A silent condition of the same class in R CMD INSTALL/check, so it can't
add warnings to their logs but can still be caught.

## Usage

``` r
.testdata_fallback_warn(tag, cnd)
```

## Arguments

- tag:

  `character(1)` The release used.

- cnd:

  `condition` Why the lookup failed.

## Value

`NULL`, invisibly.
