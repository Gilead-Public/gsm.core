# Write snapshot.json for files already in a folder

Write snapshot.json for files already in a folder

## Usage

``` r
write_snapshot_json(dir, objects, key, packages = NULL, metadata = NULL)
```

## Arguments

- dir:

  `character(1)` Snapshot folder containing the files.

- objects:

  `character` or `list` Named; object name -\> file name (relative to
  `dir`). Checksums are computed from the files.

- key:

  `character(1)` Version key.

- packages:

  `list` Optional output of
  [`package_versions()`](https://gilead-public.github.io/gsm.core/dev/reference/package_versions.md).

- metadata:

  `list` Optional named list, stored as-is.

## Value

`list` The snapshot description, invisibly.
