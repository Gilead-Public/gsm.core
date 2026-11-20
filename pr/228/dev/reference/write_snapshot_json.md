# Write snapshot.json for files already in a folder

**\[experimental\]**

## Usage

``` r
write_snapshot_json(dir, objects, key, packages = NULL, metadata = NULL)
```

## Arguments

- dir:

  `character(1)` Snapshot folder containing the files.

- objects:

  `character` or `list` Named; object name -\> RDS file name (relative
  to `dir`).

- key:

  `character(1)` Version key.

- packages:

  `list` Optional output of
  [`package_versions()`](https://gilead-public.github.io/gsm.core/dev/reference/package_versions.md).

- metadata:

  `list` Optional named list, stored as-is.

## Value

`list` The snapshot description, invisibly.

## Details

Describes RDS files already in a snapshot folder, reading each one to
record its object's
[`fresh_digest()`](https://gilead-public.github.io/gsm.core/dev/reference/fresh_digest.md).
Part of gsm.core's "refresh" tools, exported for other gsm packages
(e.g. gsm.datasim).

## See also

Other refresh:
[`fresh_digest()`](https://gilead-public.github.io/gsm.core/dev/reference/fresh_digest.md),
[`fresh_fingerprint()`](https://gilead-public.github.io/gsm.core/dev/reference/fresh_fingerprint.md),
[`fresh_inputs_hash()`](https://gilead-public.github.io/gsm.core/dev/reference/fresh_inputs_hash.md),
[`package_versions()`](https://gilead-public.github.io/gsm.core/dev/reference/package_versions.md),
[`read_snapshot()`](https://gilead-public.github.io/gsm.core/dev/reference/read_snapshot.md)

## Examples

``` r
dir <- file.path(tempdir(), "snapshot-example")
dir.create(dir)
saveRDS(mtcars, file.path(dir, "cars.rds"))
digests <- list(cars = fresh_digest(mtcars))
write_snapshot_json(
  dir,
  objects = c(cars = "cars.rds"),
  key = paste0("sha256:", fresh_fingerprint(digests))
)
read_snapshot(dir)$objects
#> $cars
#> $cars$file
#> [1] "cars.rds"
#> 
#> $cars$digest
#> [1] "600df8759318fe0d3e7cd227dfb889264b9395236a2336b9c1d32f83ed509279"
#> 
#> 
unlink(dir, recursive = TRUE)
```
