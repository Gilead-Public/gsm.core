# Tell the user if installed packages are newer than a snapshot's

Tell the user if installed packages are newer than a snapshot's

## Usage

``` r
.snapshot_check_packages(snapshot)
```

## Arguments

- snapshot:

  `list` Output of
  [`read_snapshot()`](https://gilead-public.github.io/gsm.core/dev/reference/read_snapshot.md).

## Value

`character` Names of newer packages, invisibly.
