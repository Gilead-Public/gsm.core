# Run a workflow via it's YAML specification.

**\[deprecated\]** `RunWorkflow()` has moved to
[`workr::RunWorkflow()`](https://gilead-biostats.github.io/workr/reference/RunWorkflow.html).
This wrapper remains for backward compatibility in `{gsm.core}`.

Attempts to run a single assessment (`lWorkflow`) using shared data
(`lData`) and metadata (`lMapping`). Calls `RunStep` for each item in
`lWorkflow$workflow` and saves the results to `lWorkflow`.

## Usage

``` r
RunWorkflow(
  lWorkflow,
  lData = NULL,
  lConfig = NULL,
  bReturnResult = TRUE,
  bKeepInputData = TRUE
)
```

## Arguments

- lWorkflow:

  `list` A named list of metadata defining how the workflow should be
  run.

- lData:

  `list` A named list of domain-level data frames.

- lConfig:

  `list` A configuration object with two methods:

  - `LoadData`: A function that loads data specified in
    `lWorkflow$spec`.

  - `SaveData`: A function that saves data returned by the last step in
    `lWorkflow$steps`.

- bReturnResult:

  `boolean` should *only* the result from the last step (`lResults`) be
  returned? If false, the full workflow (including `lResults`) is
  returned. Default is `TRUE`.

- bKeepInputData:

  `boolean` should the input data be included in `lData` after the
  workflow is run? Only relevant when bReturnResult is FALSE. Default is
  `TRUE`.

## Value

Object containing the results of the workflow's last step (if
`bLastResult` is `TRUE`) or the full workflow object (if
`bReturnResults` is `TRUE`) or the full workflow object (if
`bReturnResults` is `FALSE`).

`list` contains just lData if `bReturnData` is `TRUE`, otherwise returns
the full `lWorkflow` object.

## Examples

``` r
# Generate mapped input data to metric workflow.
lMappingWorkflows <- workr::MakeWorkflowList(
  strNames = c("AE", "SUBJ"),
  strPath = "example_workflow/1_mappings",
  strPackage = "gsm.core",
  bExact = TRUE
)
lRawData <- list(
  Raw_SUBJ = gsm.core::lSource$Raw_SUBJ,
  Raw_AE = gsm.core::lSource$Raw_AE
)

lMappedData <- workr::RunWorkflows(
  lMappingWorkflows,
  lRawData
)
#> [INFO] Running 2 Workflows
#> [INFO] Initializing `Mapped_AE` Workflow
#> [INFO] Checking data against spec
#> [INFO] Workflow Step 1 of 1: `=`
#> [INFO] Evaluating 2 parameter(s) for `=`
#> [INFO] lhs = Mapped_AE: No matching data found. Passing 'Mapped_AE' as a string.
#> [INFO] rhs = Raw_AE: Passing lData$Raw_AE.
#> [INFO] Calling `=`
#> [INFO] 3000x11 data.frame saved as `lData$Mapped_AE`.
#> [INFO] Returning results from final step: 3000x11 data.frame`.
#> [INFO] Completed `Mapped_AE` Workflow
#> [INFO] Initializing `Mapped_SUBJ` Workflow
#> [INFO] Checking data against spec
#> [INFO] Workflow Step 1 of 1: `gsm.core::RunQuery`
#> [INFO] Evaluating 2 parameter(s) for `gsm.core::RunQuery`
#> [INFO] df = Raw_SUBJ: Passing lData$Raw_SUBJ.
#> [INFO] strQuery = SELECT * FROM df WHERE enrollyn == 'Y': No matching data found. Passing 'SELECT * FROM df WHERE enrollyn == 'Y'' as a string.
#> [INFO] Calling `gsm.core::RunQuery`
#> [INFO] Creating a new temporary DuckDB connection.
#> duckdb keeps downloaded extensions and secrets in a temporary directory:
#> ℹ /tmp/Rtmp2a23DN/duckdb
#> This is removed when the R session ends.
#> • Extensions are re-downloaded each session.
#> • Secrets are lost.
#> ℹ Run duckdb(shared_home = TRUE) (or create ~/.duckdb) to keep them (suitable for most users).
#> ℹ Run duckdb(shared_home = FALSE) to accept the temporary directory (and silence this message).
#> ℹ See ?duckdb_storage for details and alternatives.
#> [INFO] SQL Query complete: 743 rows returned.
#> [INFO] Disconnected from temporary DuckDB connection.
#> [INFO] 743x15 data.frame saved as `lData$Mapped_SUBJ`.
#> [INFO] Returning results from final step: 743x15 data.frame`.
#> [INFO] Completed `Mapped_SUBJ` Workflow

# Run the metric workflow.
lMetricWorkflow <- workr::MakeWorkflowList(
  strPath = "example_workflow/2_metrics",
  strNames = c("kri0001", "kri0002"),
  strPackage = "gsm.core"
)$kri0001
lMetricOutput <- workr::RunWorkflow(
  lMetricWorkflow,
  lMappedData
)
#> [INFO] Initializing `Analysis_kri0001` Workflow
#> [INFO] Checking data against spec
#> [INFO] Workflow Step 1 of 7: `gsm.core::ParseThreshold`
#> [INFO] Evaluating 1 parameter(s) for `gsm.core::ParseThreshold`
#> [INFO] strThreshold = Threshold: Passing lMeta$Threshold.
#> [INFO] Calling `gsm.core::ParseThreshold`
#> Parsed -2,-1,2,3 to numeric vector: -2, -1, 2, 3
#> [INFO] double of length 4 saved as `lData$vThreshold`.
#> [INFO] Workflow Step 2 of 7: `gsm.core::Input_Rate`
#> [INFO] Evaluating 9 parameter(s) for `gsm.core::Input_Rate`
#> [INFO] dfSubjects = Mapped_SUBJ: Passing lData$Mapped_SUBJ.
#> [INFO] dfNumerator = Mapped_AE: Passing lData$Mapped_AE.
#> [INFO] dfDenominator = Mapped_SUBJ: Passing lData$Mapped_SUBJ.
#> [INFO] strSubjectCol = subjid: No matching data found. Passing 'subjid' as a string.
#> [INFO] strGroupCol = invid: No matching data found. Passing 'invid' as a string.
#> [INFO] strGroupLevel = GroupLevel: Passing lMeta$GroupLevel.
#> [INFO] strNumeratorMethod = Count: No matching data found. Passing 'Count' as a string.
#> [INFO] strDenominatorMethod = Sum: No matching data found. Passing 'Sum' as a string.
#> [INFO] strDenominatorCol = timeonstudy: No matching data found. Passing 'timeonstudy' as a string.
#> [INFO] Calling `gsm.core::Input_Rate`
#> [INFO] 743x6 data.frame saved as `lData$Analysis_Input`.
#> [INFO] Workflow Step 3 of 7: `gsm.core::Transform_Rate`
#> [INFO] Evaluating 1 parameter(s) for `gsm.core::Transform_Rate`
#> [INFO] dfInput = Analysis_Input: Passing lData$Analysis_Input.
#> [INFO] Calling `gsm.core::Transform_Rate`
#> [INFO] 142x5 data.frame saved as `lData$Analysis_Transformed`.
#> [INFO] Workflow Step 4 of 7: `gsm.core::Analyze_NormalApprox`
#> [INFO] Evaluating 2 parameter(s) for `gsm.core::Analyze_NormalApprox`
#> [INFO] dfTransformed = Analysis_Transformed: Passing lData$Analysis_Transformed.
#> [INFO] strType = AnalysisType: Passing lMeta$AnalysisType.
#> [INFO] Calling `gsm.core::Analyze_NormalApprox`
#> `OverallMetric`, `Factor`, and `Score` columns created from normal
#> approximation.
#> [INFO] 142x8 data.frame saved as `lData$Analysis_Analyzed`.
#> [INFO] Workflow Step 5 of 7: `gsm.core::Flag`
#> [INFO] Evaluating 4 parameter(s) for `gsm.core::Flag`
#> [INFO] dfAnalyzed = Analysis_Analyzed: Passing lData$Analysis_Analyzed.
#> [INFO] vThreshold = vThreshold: Passing lData$vThreshold.
#> [INFO] nAccrualThreshold = AccrualThreshold: Passing lMeta$AccrualThreshold.
#> [INFO] strAccrualMetric = AccrualMetric: Passing lMeta$AccrualMetric.
#> [INFO] Calling `gsm.core::Flag`
#> ℹ 20 Group(s) have insufficient sample size due to KRI denominator less than 30: 0X6850, 0X9625, 0X4921, 0X5738, 0X4592, 0X1177, 0X4914, 0X7463, 0X6839, 0X3401, 0X5880, 0X6828, 0X3030, 0X2826, 0X066, 0X8451, 0X7102, 0X7915, 0X1383, 0X2060
#> These group(s) will not have KRI score and flag summarized.
#> ℹ Sorted dfFlagged using custom Flag order: 2.Sorted dfFlagged using custom Flag order: -2.Sorted dfFlagged using custom Flag order: 1.Sorted dfFlagged using custom Flag order: -1.Sorted dfFlagged using custom Flag order: 0.
#> [INFO] 142x9 data.frame saved as `lData$Analysis_Flagged`.
#> [INFO] Workflow Step 6 of 7: `gsm.core::Summarize`
#> [INFO] Evaluating 1 parameter(s) for `gsm.core::Summarize`
#> [INFO] dfFlagged = Analysis_Flagged: Passing lData$Analysis_Flagged.
#> [INFO] Calling `gsm.core::Summarize`
#> [INFO] 142x7 data.frame saved as `lData$Analysis_Summary`.
#> [INFO] Workflow Step 7 of 7: `list`
#> [INFO] Evaluating 6 parameter(s) for `list`
#> [INFO] ID = ID: Passing lMeta$ID.
#> [INFO] Analysis_Input = Analysis_Input: Passing lData$Analysis_Input.
#> [INFO] Analysis_Transformed = Analysis_Transformed: Passing lData$Analysis_Transformed.
#> [INFO] Analysis_Analyzed = Analysis_Analyzed: Passing lData$Analysis_Analyzed.
#> [INFO] Analysis_Flagged = Analysis_Flagged: Passing lData$Analysis_Flagged.
#> [INFO] Analysis_Summary = Analysis_Summary: Passing lData$Analysis_Summary.
#> [INFO] Calling `list`
#> [INFO] list of length 6 saved as `lData$lAnalysis`.
#> [INFO] Returning results from final step: list of length 6`.
#> [INFO] Completed `Analysis_kri0001` Workflow
```
