# Check whether test data can be loaded

**\[experimental\]**

## Usage

``` r
testdata_is_available(objects = testdata_object_names())
```

## Arguments

- objects:

  `character` Names of the objects to check, from
  [`testdata_object_names()`](https://gilead-public.github.io/gsm.core/dev/reference/testdata_object_names.md).
  Defaults to all of them.

## Value

`logical(1)` `TRUE` if every object in `objects` loaded, otherwise
`FALSE`.

## Details

Tries to load test data objects (e.g.
[lSource](https://gilead-public.github.io/gsm.core/dev/reference/lSource.md))
and reports whether that worked, without erroring. Objects are read from
the snapshot folder set by
[`use_testdata_snapshot()`](https://gilead-public.github.io/gsm.core/dev/reference/use_testdata_snapshot.md)
or from the cache if possible, so this can return `TRUE` offline.
Otherwise they're downloaded, so the first call can be slow. Useful for
skipping examples, tests, or vignettes that need the data.

## Examples

``` r
testdata_is_available("lSource")
#> [1] TRUE
```
