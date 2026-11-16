# A release's snapshot.json

Releases are immutable, so this is cached in memory and on disk
indefinitely. If a local build (see
[`rebuild_local_testdata()`](https://gilead-public.github.io/gsm.core/dev/reference/rebuild_local_testdata.md))
has the same fingerprint, its snapshot is used instead, with `dir` set,
so objects are copied from it rather than downloaded.

## Usage

``` r
.testdata_snapshot(tag)
```

## Arguments

- tag:

  `character(1)` Release tag, e.g. `"data-8cde53949d4d"`.

## Value

`list` Output of
[`parse_snapshot()`](https://gilead-public.github.io/gsm.core/dev/reference/parse_snapshot.md).
