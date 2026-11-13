# reportingMetrics Dataset

**\[stable\]**

## Usage

``` r
reportingMetrics
```

## Format

A data frame with about 24 rows and 27 columns:

- MetricID:

  unique metric identifier

- GroupLevel:

  level of grouping variable

- Abbreviation:

  abbreviation for the metric

- Metric:

  name of the metric

- Numerator:

  data source for the numerator

- Denominator:

  data source for the denominator

- Model:

  model used to calculate metric

- Score:

  type of score reported

- Type:

  statistical outcome type

- Threshold:

  thresholds to be used for bounds and flags

- RiskScoreWeight:

  weight assigned to the risk score

- AccrualThreshold:

  minimum numerator required to return a score and calculate a flag

- AccrualMetric:

  metric used to apply threshold to

- ID:

  ID

- Priority:

  Priority in workflow

- AnalysisType:

  analysis type

- Flag:

  thresholds to be used for vFlags argument

- ScoreCol:

  Column used for
  [`Analyze_Identity()`](https://gilead-public.github.io/gsm.core/dev/reference/Analyze_Identity.md)

- nNumDeviations:

  Number of standard deviations to flag QTL

- nPropRate:

  Proposed threshold

- Active:

  logical flag indicating whether the metric is active

- GenerateRiskSignal:

  logical flag indicating whether to generate a risk signal

- WindowDays:

  number of days in the metric's observation window

- ValueCol:

  column of repeated measurements evaluated by repeat-measure metrics

- WindowLength:

  number of consecutive measurements in each repeat-measure window

- NumeratorCol:

  column used as the numerator by repeat-measure metrics

- DenominatorCol:

  column used as the denominator by repeat-measure metrics

## Source

`reportingMetrics.rds` from a `data-*` release of
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
