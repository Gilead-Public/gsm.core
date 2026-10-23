# reportingActionLog Dataset

Deterministic longitudinal ActionLog records aligned with flagged site
KRI rows in
[reportingResults](https://gilead-public.github.io/gsm.core/dev/reference/reportingResults.md).
Each extraction is a complete frozen read of signals known at that
snapshot. Multiple actions and unactioned signals follow the
source-neutral grail Action Log schema; the result key is not unique
without extraction, signal, and action identifiers.

## Usage

``` r
reportingActionLog
```

## Format

A data frame with 629 rows and 33 columns:

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

Generated through `gsm.datasim::simulate_action_log()` by
`data-raw/generate_action_log_fixture.R`.
