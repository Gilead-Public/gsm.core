# Write a snapshot of a handle's values

Body of `FreshHandle$save_snapshot()`.

## Usage

``` r
.fresh_save_snapshot(self, private, dir, names, packages, key, metadata)
```

## Arguments

- self, private:

  `R6` The handle's `self` and `private`.

- dir:

  `character(1)` Snapshot folder to write. Created if needed.

- names:

  `character` Binding names to save. `NULL` saves all.

- packages:

  `character` Package names whose installed versions are recorded, or
  `NULL`.

- key:

  `character(1)` Version key. `NULL` uses the handle's current key.

- metadata:

  `list` Optional named list, stored as-is.

## Value

`list` The snapshot description, invisibly.
