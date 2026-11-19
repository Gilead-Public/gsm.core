# Does a folder hold a readable local build?

Does a folder hold a readable local build?

## Usage

``` r
.testdata_local_exists(dir)
```

## Arguments

- dir:

  `character(1)` or `NULL`.

## Value

`logical(1)` `TRUE` if `dir` has a valid `snapshot.json`, so a damaged
build can't take priority over usable published data.
