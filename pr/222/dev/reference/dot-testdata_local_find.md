# Find a local build for a release tag

Find a local build for a release tag

## Usage

``` r
.testdata_local_find(tag)
```

## Arguments

- tag:

  `character(1)` Release tag, e.g. `"data-8cde53949d4d"`.

## Value

`list` Output of
[`read_snapshot()`](https://gilead-public.github.io/gsm.core/dev/reference/read_snapshot.md)
with `key` set to the release's, or `NULL` if no valid local build has
that fingerprint.
