# A release's snapshot.json

Releases are immutable, so this is cached in memory and on disk
indefinitely.

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
