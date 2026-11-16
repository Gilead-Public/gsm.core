# reportingBounds Dataset

**\[stable\]**

## Usage

``` r
reportingBounds
```

## Format

A data frame with about 33804 rows and 8 columns:

- Threshold:

  number of standard deviations that the upper and lower bounds are
  based on

- Denominator:

  calculated denominator value

- LogDenominator:

  calculated log denominator value

- Numerator:

  calculated numerator value

- Metric:

  calculated rate/metric value

- MetricID:

  unique metric identifier

- StudyID:

  unique study identifier

- SnapshotDate:

  date of the snapshot

## Source

`reportingBounds.rds` from a `data-*` release of
<https://github.com/Gilead-Public/gsm.datasim/releases>.

## Details

Downloaded on first use from a gsm.datasim test data release and cached
locally. The release is automatically chosen to match the installed gsm
packages. To change where or how the data is cached, see
[`use_testdata_cache_dir()`](https://gilead-public.github.io/gsm.core/dev/reference/use_testdata_cache_dir.md).

## Release selection

The data comes from, in order of priority:

- [`use_testdata_snapshot()`](https://gilead-public.github.io/gsm.core/dev/reference/use_testdata_snapshot.md):
  a local snapshot folder. Nothing is downloaded or cached.

- [`use_testdata_tag()`](https://gilead-public.github.io/gsm.core/dev/reference/use_testdata_snapshot.md):
  an exact `data-*` release tag.

- Otherwise, the release built with the gsm packages you have installed,
  looked up in gsm.datasim's test data index:

  1.  If gsm.datasim built the data with exactly your installed
      versions, that data is used.

  2.  Otherwise, each installed package narrows the candidates: by its
      GitHub commit (`RemoteSha`) if that commit was built, else by the
      same version, else by the newest built version no higher than
      yours. Packages that aren't installed don't narrow anything.

  3.  Among the remaining candidates, the most recently built is used.

  If nothing matches, an error names the package that ruled out every
  build. Usually that means updating it (or the other gsm packages) to a
  compatible set.

Each override can also be set with an environment variable before
gsm.core loads; see
[`use_testdata_snapshot()`](https://gilead-public.github.io/gsm.core/dev/reference/use_testdata_snapshot.md).
