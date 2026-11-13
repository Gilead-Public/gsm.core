# Installed versions of packages

**\[experimental\]**

## Usage

``` r
package_versions(packages)
```

## Arguments

- packages:

  `character` Package names.

## Value

`list` Named by package; each element has `version` and `remote_sha`
(both `NA` when unknown or not installed).

## Details

Records the version and `RemoteSha` (set when installed from GitHub,
e.g. with pak or remotes) of each package. Pass the result to
`write_snapshot_json(packages = )` to record which package versions
built a snapshot, or call it from a
[`keep_fresh()`](https://gilead-public.github.io/gsm.core/dev/reference/keep_fresh.md)
checker and store the result in its `state` to decide whether the data
needs checking again (e.g. skip a remote lookup until installed packages
change).

## See also

Other refresh:
[`fresh_digest()`](https://gilead-public.github.io/gsm.core/dev/reference/fresh_digest.md),
[`fresh_fingerprint()`](https://gilead-public.github.io/gsm.core/dev/reference/fresh_fingerprint.md),
[`fresh_inputs_hash()`](https://gilead-public.github.io/gsm.core/dev/reference/fresh_inputs_hash.md),
[`read_snapshot()`](https://gilead-public.github.io/gsm.core/dev/reference/read_snapshot.md),
[`write_snapshot_json()`](https://gilead-public.github.io/gsm.core/dev/reference/write_snapshot_json.md)

## Examples

``` r
package_versions(c("gsm.core", "not.a.package"))
#> $gsm.core
#> $gsm.core$version
#> [1] "1.3.2.9000"
#> 
#> $gsm.core$remote_sha
#> [1] NA
#> 
#> 
#> $not.a.package
#> $not.a.package$version
#> [1] NA
#> 
#> $not.a.package$remote_sha
#> [1] NA
#> 
#> 
```
