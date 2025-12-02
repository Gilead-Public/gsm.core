# reportingMetrics Dataset

**\[stable\]**

## Usage

``` r
reportingMetrics
```

## Format

A data frame with 15 rows and 19 columns:

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

- nNumDeviations:

  Number of standard deviations to flag QTL

- nPropRate:

  Proposed threshold

## Source

Generated from `reportingMetrics.csv` dataset in the `gsm.core` package.
