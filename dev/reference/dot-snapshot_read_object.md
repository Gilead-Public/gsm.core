# Read and verify one object from a snapshot

Read and verify one object from a snapshot

## Usage

``` r
.snapshot_read_object(snapshot, name)
```

## Arguments

- snapshot:

  `list` Output of
  [`read_snapshot()`](https://gilead-public.github.io/gsm.core/dev/reference/read_snapshot.md).

- name:

  `character(1)` Object name in `snapshot$objects`.

## Value

The object read from its RDS file.
