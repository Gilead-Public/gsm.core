# Read a snapshot's description

**\[experimental\]**

## Usage

``` r
read_snapshot(dir)
```

## Arguments

- dir:

  `character(1)` Snapshot folder containing `snapshot.json`.

## Value

`list` The parsed `snapshot.json`, with `dir` (normalized) added.

## Details

Reads and validates `snapshot.json` in a snapshot folder, such as one
written by
[`write_snapshot_json()`](https://gilead-public.github.io/gsm.core/dev/reference/write_snapshot_json.md).
Part of gsm.core's "refresh" tools, exported for other gsm packages
(e.g. gsm.datasim).

## See also

Other refresh:
[`fresh_digest()`](https://gilead-public.github.io/gsm.core/dev/reference/fresh_digest.md),
[`fresh_fingerprint()`](https://gilead-public.github.io/gsm.core/dev/reference/fresh_fingerprint.md),
[`fresh_inputs_hash()`](https://gilead-public.github.io/gsm.core/dev/reference/fresh_inputs_hash.md),
[`package_versions()`](https://gilead-public.github.io/gsm.core/dev/reference/package_versions.md),
[`write_snapshot_json()`](https://gilead-public.github.io/gsm.core/dev/reference/write_snapshot_json.md)
