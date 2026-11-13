# Hash the package versions that built something

**\[experimental\]**

## Usage

``` r
fresh_inputs_hash(packages)
```

## Arguments

- packages:

  `list` Named by package; each element has `version` and `remote_sha`,
  as from
  [`package_versions()`](https://gilead-public.github.io/gsm.core/dev/reference/package_versions.md).

## Value

`character(1)` A 64-character lowercase hex string.

## Details

The SHA-256 of one `"<package> <version> <remote_sha>"` line per package
(a missing SHA as `NA`), sorted by name in C-locale order and joined
with `"\n"`. gsm.datasim records it as each test data build's
`inputs_hash`, and gsm.core uses it to find the build that matches the
installed packages.

## See also

Other refresh:
[`fresh_digest()`](https://gilead-public.github.io/gsm.core/dev/reference/fresh_digest.md),
[`fresh_fingerprint()`](https://gilead-public.github.io/gsm.core/dev/reference/fresh_fingerprint.md),
[`package_versions()`](https://gilead-public.github.io/gsm.core/dev/reference/package_versions.md),
[`read_snapshot()`](https://gilead-public.github.io/gsm.core/dev/reference/read_snapshot.md),
[`write_snapshot_json()`](https://gilead-public.github.io/gsm.core/dev/reference/write_snapshot_json.md)

## Examples

``` r
fresh_inputs_hash(package_versions("gsm.core"))
#> [1] "66b7cc4a8d293228df17af92cdb17e4015301a36f44f209f666d75b6df7c06be"
```
