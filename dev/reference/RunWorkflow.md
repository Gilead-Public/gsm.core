# Run a workflow via it's YAML specification.

**\[stable\]**

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
lMappingWorkflows <- MakeWorkflowList(
  strNames = c("AE", "SUBJ"),
  strPath = "example_workflow/1_mappings",
  strPackage = "gsm.core",
  bExact = TRUE
)
lRawData <- list(
  Raw_SUBJ = gsm.core::lSource$Raw_SUBJ,
  Raw_AE = gsm.core::lSource$Raw_AE
)

lMappedData <- RunWorkflows(
  lMappingWorkflows,
  lRawData
)
#> 
#> ── Running 2 Workflows ─────────────────────────────────────────────────────────
#> 
#> ── Initializing `Mapped_AE` Workflow ───────────────────────────────────────────
#> 
#> ── Checking data against spec 
#> → All 1 data.frame(s) in the spec are present in the data: Raw_AE
#> → All specified columns in Raw_AE are in the expected format
#> → All 2 specified column(s) in the spec are present in the data: Raw_AE$subjid, Raw_AE$aeser
#> 
#> ── Workflow Step 1 of 1: `=` ──
#> 
#> ── Evaluating 2 parameter(s) for `=` 
#> ℹ lhs = Mapped_AE: No matching data found. Passing 'Mapped_AE' as a string.
#> ✔ rhs = Raw_AE: Passing lData$Raw_AE.
#> 
#> ── Calling `=` 
#> 
#> ── 3000x11 data.frame saved as `lData$Mapped_AE`. 
#> 
#> ── Returning results from final step: 3000x11 data.frame`. ──
#> 
#> ── Completed `Mapped_AE` Workflow ──────────────────────────────────────────────
#> 
#> ── Initializing `Mapped_SUBJ` Workflow ─────────────────────────────────────────
#> 
#> ── Checking data against spec 
#> → All 1 data.frame(s) in the spec are present in the data: Raw_SUBJ
#> → All specified columns in Raw_SUBJ are in the expected format
#> → All 7 specified column(s) in the spec are present in the data: Raw_SUBJ$studyid, Raw_SUBJ$invid, Raw_SUBJ$country, Raw_SUBJ$subjid, Raw_SUBJ$subject_nsv, Raw_SUBJ$enrollyn, Raw_SUBJ$timeonstudy
#> 
#> ── Workflow Step 1 of 1: `gsm.core::RunQuery` ──
#> 
#> ── Evaluating 2 parameter(s) for `gsm.core::RunQuery` 
#> ✔ df = Raw_SUBJ: Passing lData$Raw_SUBJ.
#> ℹ strQuery = SELECT * FROM df WHERE enrollyn == 'Y': No matching data found. Passing 'SELECT * FROM df WHERE enrollyn == 'Y'' as a string.
#> 
#> ── Calling `gsm.core::RunQuery` 
#> Creating a new temporary DuckDB connection.
#> ✔ SQL Query complete: 760 rows returned.
#> Disconnected from temporary DuckDB connection.
#> 
#> ── 760x15 data.frame saved as `lData$Mapped_SUBJ`. 
#> 
#> ── Returning results from final step: 760x15 data.frame`. ──
#> 
#> ── Completed `Mapped_SUBJ` Workflow ────────────────────────────────────────────

# Run the metric workflow.
lMetricWorkflow <- MakeWorkflowList(
  strPath = "example_workflow/2_metrics",
  strNames = c("kri0001", "kri0002"),
  strPackage = "gsm.core"
)$kri0001
lMetricOutput <- RunWorkflow(
  lMetricWorkflow,
  lMappedData
)
#> 
#> ── Initializing `Analysis_kri0001` Workflow ────────────────────────────────────
#> 
#> ── Checking data against spec 
#> → All 2 data.frame(s) in the spec are present in the data: Mapped_AE, Mapped_SUBJ
#> → All specified columns in Mapped_AE are in the expected format
#> → All specified columns in Mapped_SUBJ are in the expected format
#> → All 4 specified column(s) in the spec are present in the data: Mapped_AE$subjid, Mapped_SUBJ$subjid, Mapped_SUBJ$invid, Mapped_SUBJ$timeonstudy
#> 
#> ── Workflow Step 1 of 7: `gsm.core::ParseThreshold` ──
#> 
#> ── Evaluating 1 parameter(s) for `gsm.core::ParseThreshold` 
#> ✔ strThreshold = Threshold: Passing lMeta$Threshold.
#> 
#> ── Calling `gsm.core::ParseThreshold` 
#> Parsed -2,-1,2,3 to numeric vector: -2, -1, 2, 3
#> 
#> ── double of length 4 saved as `lData$vThreshold`. 
#> 
#> ── Workflow Step 2 of 7: `gsm.core::Input_Rate` ──
#> 
#> ── Evaluating 9 parameter(s) for `gsm.core::Input_Rate` 
#> ✔ dfSubjects = Mapped_SUBJ: Passing lData$Mapped_SUBJ.
#> ✔ dfNumerator = Mapped_AE: Passing lData$Mapped_AE.
#> ✔ dfDenominator = Mapped_SUBJ: Passing lData$Mapped_SUBJ.
#> ℹ strSubjectCol = subjid: No matching data found. Passing 'subjid' as a string.
#> ℹ strGroupCol = invid: No matching data found. Passing 'invid' as a string.
#> ✔ strGroupLevel = GroupLevel: Passing lMeta$GroupLevel.
#> ℹ strNumeratorMethod = Count: No matching data found. Passing 'Count' as a string.
#> ℹ strDenominatorMethod = Sum: No matching data found. Passing 'Sum' as a string.
#> ℹ strDenominatorCol = timeonstudy: No matching data found. Passing 'timeonstudy' as a string.
#> 
#> ── Calling `gsm.core::Input_Rate` 
#> 
#> ── 760x6 data.frame saved as `lData$Analysis_Input`. 
#> 
#> ── Workflow Step 3 of 7: `gsm.core::Transform_Rate` ──
#> 
#> ── Evaluating 1 parameter(s) for `gsm.core::Transform_Rate` 
#> ✔ dfInput = Analysis_Input: Passing lData$Analysis_Input.
#> 
#> ── Calling `gsm.core::Transform_Rate` 
#> 
#> ── 148x5 data.frame saved as `lData$Analysis_Transformed`. 
#> 
#> ── Workflow Step 4 of 7: `gsm.core::Analyze_NormalApprox` ──
#> 
#> ── Evaluating 2 parameter(s) for `gsm.core::Analyze_NormalApprox` 
#> ✔ dfTransformed = Analysis_Transformed: Passing lData$Analysis_Transformed.
#> ✔ strType = AnalysisType: Passing lMeta$AnalysisType.
#> 
#> ── Calling `gsm.core::Analyze_NormalApprox` 
#> `OverallMetric`, `Factor`, and `Score` columns created from normal
#> approximation.
#> 
#> ── 148x8 data.frame saved as `lData$Analysis_Analyzed`. 
#> 
#> ── Workflow Step 5 of 7: `gsm.core::Flag` ──
#> 
#> ── Evaluating 4 parameter(s) for `gsm.core::Flag` 
#> ✔ dfAnalyzed = Analysis_Analyzed: Passing lData$Analysis_Analyzed.
#> ✔ vThreshold = vThreshold: Passing lData$vThreshold.
#> ✔ nAccrualThreshold = AccrualThreshold: Passing lMeta$AccrualThreshold.
#> ✔ strAccrualMetric = AccrualMetric: Passing lMeta$AccrualMetric.
#> 
#> ── Calling `gsm.core::Flag` 
#> ℹ 27 Group(s) have insufficient sample size due to KRI denominator less than 30: 0X1935, 0X1273, 0X5185, 0X3759, 0X8616, 0X2062, 0X4275, 0X8361, 0X7246, 0X4028, 0X4875, 0X8627, 0X7913, 0X4744, 0X9766, 0X4424, 0X9082, 0X6123, 0X6440, 0X4976, 0X4703, 0X2030, 0X5217, 0X1841, 0X4612, 0X7734, 0X6068
#> These group(s) will not have KRI score and flag summarized.
#> ℹ Sorted dfFlagged using custom Flag order: 2.Sorted dfFlagged using custom Flag order: -2.Sorted dfFlagged using custom Flag order: 1.Sorted dfFlagged using custom Flag order: -1.Sorted dfFlagged using custom Flag order: 0.
#> 
#> ── 148x9 data.frame saved as `lData$Analysis_Flagged`. 
#> 
#> ── Workflow Step 6 of 7: `gsm.core::Summarize` ──
#> 
#> ── Evaluating 1 parameter(s) for `gsm.core::Summarize` 
#> ✔ dfFlagged = Analysis_Flagged: Passing lData$Analysis_Flagged.
#> 
#> ── Calling `gsm.core::Summarize` 
#> 
#> ── 148x7 data.frame saved as `lData$Analysis_Summary`. 
#> 
#> ── Workflow Step 7 of 7: `list` ──
#> 
#> ── Evaluating 6 parameter(s) for `list` 
#> ✔ ID = ID: Passing lMeta$ID.
#> ✔ Analysis_Input = Analysis_Input: Passing lData$Analysis_Input.
#> ✔ Analysis_Transformed = Analysis_Transformed: Passing lData$Analysis_Transformed.
#> ✔ Analysis_Analyzed = Analysis_Analyzed: Passing lData$Analysis_Analyzed.
#> ✔ Analysis_Flagged = Analysis_Flagged: Passing lData$Analysis_Flagged.
#> ✔ Analysis_Summary = Analysis_Summary: Passing lData$Analysis_Summary.
#> 
#> ── Calling `list` 
#> 
#> ── list of length 6 saved as `lData$lAnalysis`. 
#> 
#> ── Returning results from final step: list of length 6`. ──
#> 
#> ── Completed `Analysis_kri0001` Workflow ───────────────────────────────────────
```
