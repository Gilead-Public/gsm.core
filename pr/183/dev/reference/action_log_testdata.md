# Matching reporting inputs for the bundled ActionLog

Loads the reporting results, groups, metrics and bounds from the
immutable test data release used to generate
[reportingActionLog](https://gilead-public.github.io/gsm.core/dev/reference/reportingActionLog.md).
Uses the normal test data cache, or a matching local snapshot, without
changing the release selected for other test data objects.

## Usage

``` r
action_log_testdata()
```

## Value

A named list containing `reportingResults`, `reportingGroups`,
`reportingMetrics` and `reportingBounds`.
