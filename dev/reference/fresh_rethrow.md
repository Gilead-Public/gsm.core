# Re-signal a binding error

The default `on_error` for
[`keep_fresh()`](https://gilead-public.github.io/gsm.core/dev/reference/keep_fresh.md).

## Usage

``` r
fresh_rethrow(cnd, name)
```

## Arguments

- cnd:

  `condition` The error.

- name:

  `character(1)` The binding name (unused).

## Value

Doesn't return; signals `cnd`.
