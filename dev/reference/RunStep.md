# Run a single step in a workflow.

**\[stable\]**

Runs a single step of an assessment workflow. This function is called by
`RunWorkflow` for each step in the workflow. It prepares the parameters
for the function call and then calls the function specified in
`lStep$name` with the prepared parameters.

The primary utility of this function is to provide a prioritized parser
for function parameterization. Parameters should be specified as a named
list in `lStep$params`, where each element is a key-value pair that will
be parsed and then passed to the specified function as a set of
parameter names/values. Parameter values should be specified as scalar
strings. Those values are then pulled from `lMeta` or `lData` when
possible. When no matching `lData` or `lMeta` objects are found,
parameter values are passed through as strings. Note that parsing
vectorized parameters is not supported at this time; they are passed
directly as character vectors. To pass a vector or list, we recommend
saving it as an object in `lData`.

Full prioritization for parsing parameters is below:

1.  If a single parameter value is equal to "lMeta", the the full lMeta
    object is passed to the function (for the given paramName).

2.  If a single parameter value is equal to "lData", the full lData
    object is passed to the function.

3.  If a single parameter value is equal to "lSpec", the full lSpec
    object is passed to the function.

4.  If a single parameter value is found in names(lMeta), that property
    is pulled from lMeta (e.g. lMeta\${paramVal}) and passed to the
    function.

5.  If a single parameter value is found in names(lData), that property
    is pulled from lData (e.g. lData\${paramVal}) and passed to the
    function.

6.  Otherwise single parameter value is passed to the function as a
    string.

7.  If the parameter value is a vector, the vector is passed to the
    function as a vector or strings.

## Usage

``` r
RunStep(lStep, lData, lMeta, lSpec = NULL)
```

## Arguments

- lStep:

  `list` single workflow step (typically pulled from `lWorkflow$steps`).
  Should include the name of the function to run (`lStep$name`), name of
  the object where the function result should be saved (`lStep$output`)
  and configurable parameters (`lStep$params`) (if any)

- lData:

  `list` a named list of domain level data frames.

- lMeta:

  `list` a named list of meta data.

- lSpec:

  `list` a data specification containing required columns. See the [gsm
  Extensions
  article](https://gilead-biostats.github.io/gsm.core/articles/gsmExtensions.html).

## Value

`list` containing the results of the `lStep$name` function call should
contain `.$checks` parameter with results from `is_mapping_vald` for
each domain in `lStep$inputs`.

## Examples

``` r
wf_mapping <- MakeWorkflowList(
  strNames = c("AE", "SUBJ"),
  strPath = "example_workflow/1_mappings",
  strPackage = "gsm.core",
  bExact = TRUE
)
lWorkflow <- MakeWorkflowList(
  strPath = "example_workflow/2_metrics",
  strNames = c("kri0001", "kri0002"),
  strPackage = "gsm.core"
)
lStep <- lWorkflow[["kri0001"]][["steps"]][[1]]
lMeta <- lWorkflow[["kri0001"]][["meta"]]

lRaw <- list(
  Raw_SUBJ = gsm.core::lSource$Raw_SUBJ,
  Raw_AE = gsm.core::lSource$Raw_AE
)

mapped <- RunWorkflows(wf_mapping, lRaw)
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
#> ✔ SQL Query complete: 764 rows returned.
#> Disconnected from temporary DuckDB connection.
#> 
#> ── 764x15 data.frame saved as `lData$Mapped_SUBJ`. 
#> 
#> ── Returning results from final step: 764x15 data.frame`. ──
#> 
#> ── Completed `Mapped_SUBJ` Workflow ────────────────────────────────────────────
ae_step <- RunStep(lStep = lStep, lData = lMapped, lMeta = lMeta)
#> 
#> ── Evaluating 1 parameter(s) for `gsm.core::ParseThreshold` 
#> ✔ strThreshold = Threshold: Passing lMeta$Threshold.
#> 
#> ── Calling `gsm.core::ParseThreshold` 
#> Parsed -2,-1,2,3 to numeric vector: -2, -1, 2, 3
```
