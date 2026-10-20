# reportingMetrics Dataset

**\[stable\]**

## Usage

``` r
reportingMetrics
```

## Format

A data frame with 24 rows and 27 columns:

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

Generated from `reportingMetrics.csv` dataset in the `gsm.core` package.
