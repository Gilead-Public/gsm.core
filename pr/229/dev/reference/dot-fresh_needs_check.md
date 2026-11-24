# Is it time to run the checker again?

Is it time to run the checker again?

## Usage

``` r
.fresh_needs_check(checked_at, check)
```

## Arguments

- checked_at:

  `POSIXct` When the checker last ran, or `NULL` if never.

- check:

  `character(1)` or `numeric(1)` When to run `checker()`: `"session"`
  (once per
  [`keep_fresh()`](https://gilead-public.github.io/gsm.core/dev/reference/keep_fresh.md)
  call, i.e. once per package load), `"access"` (every access), or a
  number of seconds between checks.

## Value

`logical(1)`.
