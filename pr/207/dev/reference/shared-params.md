# Parameters used in multiple functions

Reused parameter definitions are gathered here for easier usage.

## Arguments

- dfBounds:

  `data.frame` Set of predicted percentages/rates and upper- and
  lower-bounds across the full range of sample sizes/total exposure
  values for reporting. Expected columns: `Threshold`, `Denominator`,
  `Numerator`, `Metric`, `MetricID`, `StudyID`, `SnapshotDate`.

- dfInput:

  `data.frame` Input data with one record per subject. Created by
  passing Raw+ data into
  [`Input_Rate()`](https://gilead-public.github.io/gsm.core/dev/reference/Input_Rate.md).
  Expected columns: `GroupID`, `GroupLevel`, `Numerator`, `Denominator`
  and/or columns specified in `strCountCol` and `strGroupCol`.

- lParamLabels:

  `list` Labels for parameters, with the parameters as names, and the
  label as value.

- bDebug:

  `logical` Print debug messages? Default: `FALSE`.
