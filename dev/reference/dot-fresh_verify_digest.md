# Check an object against its expected digest

Check an object against its expected digest

## Usage

``` r
.fresh_verify_digest(x, expected, source)
```

## Arguments

- x:

  The object, e.g. just read from `source`.

- expected:

  `character(1)` Expected
  [`fresh_digest()`](https://gilead-public.github.io/gsm.core/dev/reference/fresh_digest.md),
  or `NULL` to skip verification.

- source:

  `character(1)` Where `x` came from, for error messages.

## Value

`x`, if it matches. Errors otherwise.
