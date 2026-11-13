# reportingActionLog Dataset

Deterministic longitudinal ActionLog records aligned with flagged site
KRI rows in the matching reporting inputs returned by
[`action_log_testdata()`](https://gilead-public.github.io/gsm.core/dev/reference/action_log_testdata.md).
These inputs are independent of the currently selected test data
release. Each extraction is a complete frozen read of signals known at
that snapshot. Multiple actions and unactioned signals follow the
source-neutral grail Action Log schema; the result key is not unique
without extraction, signal, and action identifiers. States vary across
site/KRI pairs; earlier flags on currently green findings are closed.
Snapshot dates are labelled proxies, not verified decision dates. The
reporting history spans 59 days and does not demonstrate 90-day expiry.

## Usage

``` r
reportingActionLog
```

## Format

A data frame with 1406 rows and 33 columns:

- StudyID:

  unique study identifier

- SnapshotDate:

  date of the KRI snapshot

- GroupLevel:

  level of grouping variable

- GroupID:

  grouping variable

- MetricID:

  unique metric identifier

- State:

  ActionLog state

- ExtractionDate:

  date the synthetic ActionLog was extracted

- RiskSignalID:

  synthetic risk signal identifier

- RiskSignalURL:

  synthetic risk signal URL

- ActionID,ActionURL:

  character action identifier and URL, missing for unactioned signals

- ActionState,RiskSignalState:

  independent action and risk-signal states

- ActionCreatedDate,ActionResolvedDate:

  action lifecycle dates

- ActionCriticality:

  logical criticality; missing when unassessed

- MetricType:

  risk-signal metric type

- RiskSignalDuplicateFlag:

  whether the signal duplicates a scoring key

- RelevantSnapshotDate:

  relevant snapshot across the signal history

- RelevantSnapshotFlag:

  whether this row is the relevant snapshot

- RiskSignalAge:

  age of the signal in days

- AssignedTo,SignalDescription,RecommendedAction,ActionTaken,CTMSID,
  CreatedDate,ResolvedDate,FunctionalArea,GroupLabel,MetricLabel,
  MetricAbbreviation,Country:

  ActionLog display and action metadata

## Source

Generated through `gsm.datasim::simulate_action_log_reviews()` by
`data-raw/generate_action_log_fixture.R`.
