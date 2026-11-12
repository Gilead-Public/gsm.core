# Installed versions of packages

Records the version and `RemoteSha` (set when installed from GitHub,
e.g. with pak or remotes) of each package. Pass the result to
`write_snapshot_json(packages = )` to record which package versions
built a snapshot, or call it from a
[`keep_fresh()`](https://gilead-public.github.io/gsm.core/dev/reference/keep_fresh.md)
checker and store the result in its `state` to decide whether the data
needs checking again (e.g. skip a remote lookup until installed packages
change).

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
