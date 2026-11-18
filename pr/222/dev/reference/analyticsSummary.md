# analyticsSummary Dataset

**\[stable\]**

## Usage

``` r
analyticsSummary
```

## Format

A data frame with about 141 rows and 7 columns:

- GroupID:

  grouping variable

- GroupLevel:

  level of grouping variable

- Numerator:

  number of flags in group

- Denominator:

  total subjects in group

- Metric:

  calculated rate/metric value

- Score:

  statistical score

- Flag:

  ordinal flag to be applied

## Source

`analyticsSummary.rds` from a `data-*` release of
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
