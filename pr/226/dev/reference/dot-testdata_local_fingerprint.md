# Data fingerprint of a snapshot

Data fingerprint of a snapshot

## Usage

``` r
.testdata_local_fingerprint(snapshot)
```

## Arguments

- snapshot:

  `list` Output of
  [`read_snapshot()`](https://gilead-public.github.io/gsm.core/dev/reference/read_snapshot.md).

## Value

`character(1)`
[`fresh_fingerprint()`](https://gilead-public.github.io/gsm.core/dev/reference/fresh_fingerprint.md)
of its object digests, the same way release fingerprints are computed.
