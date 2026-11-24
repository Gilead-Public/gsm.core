# Does a folder hold a readable local build?

Checks `snapshot.json` and that every object file it lists exists.
Digests are verified when objects are read, not here, since that would
read the whole bundle on every lookup.

## Usage

``` r
.testdata_local_exists(dir)
```

## Arguments

- dir:

  `character(1)` or `NULL`.

## Value

`logical(1)` `TRUE` if `dir` looks complete, so a damaged build can't
take priority over usable published data.
