# Check a `keep_fresh(check = )` value

Check a `keep_fresh(check = )` value

## Usage

``` r
.fresh_validate_check(check)
```

## Arguments

- check:

  `character(1)` or `numeric(1)` When to run `checker()`: `"session"`
  (once per
  [`keep_fresh()`](https://gilead-public.github.io/gsm.core/dev/reference/keep_fresh.md)
  call, i.e. once per package load), `"access"` (every access), or a
  number of seconds between checks.

## Value

`character(1)` or `numeric(1)` `check`, if valid.
