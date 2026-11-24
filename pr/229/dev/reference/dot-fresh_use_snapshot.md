# Read a handle's values from a snapshot

Body of `FreshHandle$use_snapshot()`.

## Usage

``` r
.fresh_use_snapshot(self, private, dir, check_packages)
```

## Arguments

- self, private:

  `R6` The handle's `self` and `private`.

- dir:

  `character(1)` Snapshot folder to read, or `NULL` to stop using one.

- check_packages:

  `logical(1)` Tell the user if installed packages are newer than the
  snapshot's?

## Value

`FreshHandle` The handle, invisibly.
