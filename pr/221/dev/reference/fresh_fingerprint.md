# Fingerprint a set of object digests

**\[experimental\]**

## Usage

``` r
fresh_fingerprint(digests)
```

## Arguments

- digests:

  `character` or `list` Named; object name -\> digest. Names must be
  unique and non-empty.

## Value

`character(1)` A 64-character lowercase hex string.

## Details

Combines named object digests (from
[`fresh_digest()`](https://gilead-public.github.io/gsm.core/dev/reference/fresh_digest.md))
into one fingerprint: the SHA-256 of one `"<name>:<digest>"` line per
object, sorted by name in C-locale order and joined with `"\n"`. Neither
the order of `digests` nor the locale affects the result.

## See also

Other refresh:
[`fresh_digest()`](https://gilead-public.github.io/gsm.core/dev/reference/fresh_digest.md),
[`fresh_inputs_hash()`](https://gilead-public.github.io/gsm.core/dev/reference/fresh_inputs_hash.md),
[`package_versions()`](https://gilead-public.github.io/gsm.core/dev/reference/package_versions.md),
[`read_snapshot()`](https://gilead-public.github.io/gsm.core/dev/reference/read_snapshot.md),
[`write_snapshot_json()`](https://gilead-public.github.io/gsm.core/dev/reference/write_snapshot_json.md)

## Examples

``` r
digests <- lapply(list(cars = mtcars, flowers = iris), fresh_digest)
fresh_fingerprint(digests)
#> [1] "8ad0bd55f2cdacdcc6fc606b2f6ff3342d1574ab4ec14666d63ee0061d234a92"
```
