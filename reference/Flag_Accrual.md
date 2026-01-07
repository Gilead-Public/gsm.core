# Filter Flags based on Threshold and Metric

Filter Flags based on Threshold and Metric

## Usage

``` r
Flag_Accrual(dfFlagged, nAccrualThreshold, strAccrualMetric)
```

## Arguments

- dfFlagged:

  data.frame in format produced by
  [`Flag()`](https://gilead-biostats.github.io/gsm.core/reference/Flag.md).

- nAccrualThreshold:

  `numeric` Specifies the minimum value required to return a `score` and
  calculate a `flag`. Default: NULL

- strAccrualMetric:

  `character` Specifies the Metric to apply `nAccrualThreshold` to in
  order to determine the validity of a flag. Options are "Numerator",
  "Denominator" or "Difference". If "Difference" is specified, the
  threshold is based on the difference between the Denominator and the
  Numerator for a given Group. Default: `NULL`.
