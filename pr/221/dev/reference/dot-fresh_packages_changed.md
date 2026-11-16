# Have these packages changed since the checker last looked?

Have these packages changed since the checker last looked?

## Usage

``` r
.fresh_packages_changed(state, packages, slot = "packages")
```

## Arguments

- state:

  `FreshState` The checker's state store (see
  [`state_file()`](https://gilead-public.github.io/gsm.core/dev/reference/state_file.md)).
  The installed versions are saved in it.

- packages:

  `character` Package names.

- slot:

  `character(1)` State entry to use, so one checker can track several
  sets.

## Value

`logical(1)` `TRUE` if anything changed (or on first use), else `FALSE`.
