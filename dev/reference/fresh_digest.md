# Digest an R object

**\[experimental\]**

## Usage

``` r
fresh_digest(x)
```

## Arguments

- x:

  Any R object.

## Value

`character(1)` A 64-character lowercase hex string.

## Details

The SHA-256 of an R object's serialization (format version 2, skipping
R's serialization header), as recorded for snapshot objects and combined
by
[`fresh_fingerprint()`](https://gilead-public.github.io/gsm.core/dev/reference/fresh_fingerprint.md).
It digests the object rather than a file, so the same object saved by
different R versions or with different compression has the same digest.

Objects that are [`identical()`](https://rdrr.io/r/base/identical.html)
can still digest differently if their strings use different encodings
(e.g. UTF-8 vs latin1) or their attributes were set in a different
order. A deterministic build doesn't do that.

## See also

Other refresh:
[`fresh_fingerprint()`](https://gilead-public.github.io/gsm.core/dev/reference/fresh_fingerprint.md),
[`fresh_inputs_hash()`](https://gilead-public.github.io/gsm.core/dev/reference/fresh_inputs_hash.md),
[`package_versions()`](https://gilead-public.github.io/gsm.core/dev/reference/package_versions.md),
[`read_snapshot()`](https://gilead-public.github.io/gsm.core/dev/reference/read_snapshot.md),
[`write_snapshot_json()`](https://gilead-public.github.io/gsm.core/dev/reference/write_snapshot_json.md)

## Examples

``` r
fresh_digest(mtcars)
#> [1] "600df8759318fe0d3e7cd227dfb889264b9395236a2336b9c1d32f83ed509279"
```
