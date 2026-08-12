# Run a single step in a workflow.

**\[deprecated\]**

`RunStep()` has moved to
[`workr::RunStep()`](https://rdrr.io/pkg/workr/man/RunStep.html). This
wrapper remains for backward compatibility in `{gsm.core}`.

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
  article](https://gilead-public.github.io/gsm.core/articles/gsmExtensions.html).

## Value

`list` containing the results of the `lStep$name` function call should
contain `.$checks` parameter with results from `is_mapping_vald` for
each domain in `lStep$inputs`.

## Examples

``` r
wf_mapping <- workr::MakeWorkflowList(
  strNames = c("AE", "SUBJ"),
  strPath = "example_workflow/1_mappings",
  strPackage = "gsm.core",
  bExact = TRUE
)
lWorkflow <- workr::MakeWorkflowList(
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

mapped <- workr::RunWorkflows(wf_mapping, lRaw)
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
#> Warning: `RunQuery()` was deprecated in gsm.core 1.3.0.
#> ℹ Please use `workr::RunQuery()` instead.
#> ℹ The deprecated feature was likely used in the workr package.
#>   Please report the issue to the authors.
#> [INFO] Creating a new temporary DuckDB connection.
#> duckdb keeps downloaded extensions and secrets in a temporary directory:
#> ℹ /tmp/Rtmpw6eu4F/duckdb
#> This is removed when the R session ends.
#> • Extensions are re-downloaded each session.
#> • Secrets are lost.
#> ℹ Run duckdb(shared_home = TRUE) (or create ~/.duckdb) to keep them (suitable for most users).
#> ℹ Run duckdb(shared_home = FALSE) to accept the temporary directory (and silence this message).
#> ℹ See ?duckdb_storage for details and alternatives.
#> [INFO] SQL Query complete: 758 rows returned.
#> [INFO] Disconnected from temporary DuckDB connection.
#> [INFO] 758x15 data.frame saved as `lData$Mapped_SUBJ`.
#> [INFO] Returning results from final step: 758x15 data.frame`.
#> [INFO] Completed `Mapped_SUBJ` Workflow
ae_step <- workr::RunStep(lStep = lStep, lData = mapped, lMeta = lMeta)
#> [INFO] Evaluating 1 parameter(s) for `gsm.core::ParseThreshold`
#> [INFO] strThreshold = Threshold: Passing lMeta$Threshold.
#> [INFO] Calling `gsm.core::ParseThreshold`
#> Parsed -2,-1,2,3 to numeric vector: -2, -1, 2, 3
```
