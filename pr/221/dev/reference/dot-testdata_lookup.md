# Look up the test data release for the installed packages

The body of
[`.testdata_checker()`](https://gilead-public.github.io/gsm.core/dev/reference/dot-testdata_checker.md),
without its fallback.

## Usage

``` r
.testdata_lookup(state, prev)
```

## Arguments

- state:

  `FreshState` The handle's state store; the `"lookup"` entry records
  the last choice.

- prev:

  `list` The previous `"lookup"` state entry, or `NULL`.

## Value

`character(1)` The release tag.
