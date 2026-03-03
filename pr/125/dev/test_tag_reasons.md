# Test–Issue Tag Reasoning

# Test–Issue Tag Reasoning

This document records the reasoning behind each test–issue association
added in this tagging pass. Tags were applied via `qcthat` commit-based
matching (Steps 1–2), title matching (Step 3), and a manual bonus round
targeting closed issues not yet covered by any test.

Each section corresponds to a test file. The **Reason** column notes the
match type and the logic used.

------------------------------------------------------------------------

## test-Analyze_NormalApprox.R

| Test                                                      | Issue                                                         | Reason                                                                                                                                                                                                                                                                                                                                                                                        |
|-----------------------------------------------------------|---------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| rate output created as expected and has correct structure | [\#21](https://github.com/Gilead-BioStats/gsm.core/issues/21) | **Bonus round.** Issue \#21 explicitly names `test-Analyze_NormalApprox.R` as one of the files with captured warnings. This test uses `quiet_Analyze_NormalApprox()`, a wrapper that suppresses expected messages/warnings — the direct implementation of the “capture warnings so real issues aren’t missed” fix described in \#21. The `quiet_*` helper is the clearest signal in the file. |

------------------------------------------------------------------------

## test-Analyze_NormalApprox_PredictBounds.R

| Test                                                        | Issue                                                         | Reason                                                                                                                                                                                                                                      |
|-------------------------------------------------------------|---------------------------------------------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Analyze_NormalApprox_PredictBounds processes data correctly | [\#21](https://github.com/Gilead-BioStats/gsm.core/issues/21) | **Bonus round.** Issue \#21 explicitly names `test-Analyze_NormalApprox_PredictBounds.R`. This test uses `quiet_Analyze_NormalApprox_PredictBounds()`, the suppression wrapper that directly addresses the warning-capture concern in \#21. |

------------------------------------------------------------------------

## test-qual_T5_2.R

| Test                                                                                                                       | Issue                                                         | Reason                                                                                                                                                                                                                                                                                                                                                                                                                                              |
|----------------------------------------------------------------------------------------------------------------------------|---------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Qual: Given appropriate raw participant-level data, flag values are correctly assigned as NA for sites with low enrollment | [\#77](https://github.com/Gilead-BioStats/gsm.core/issues/77) | **Bonus round.** Issue \#77 is “Add `RiskScoreWeight` info to `Analysis_Flagged` via the `Flag()` function.” The test calls `Flag(..., vRiskScoreWeight = c(32, 16, 0, 1, 2))` and then removes `Weight`/`WeightMax` columns for comparison — confirming these columns are expected to be present. The `vRiskScoreWeight` parameter usage is deliberate and tests the exact feature described in \#77. Tag added alongside the pre-existing `#116`. |

------------------------------------------------------------------------

## test-RunQuery.R

| Test                                             | Issue                                                         | Reason                                                                                                                                                                                                                                                                                                                                    |
|--------------------------------------------------|---------------------------------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| RunQuery applies schema appropriately            | [\#22](https://github.com/Gilead-BioStats/gsm.core/issues/22) | **Commit match.** Issue \#22 is “Feature: DATETIME data type — support ‘timestamp’ format in RunQuery.” The test includes `Birthtime = list(type = "timestamp")` in `lColumnMapping` and asserts `class(result$Birthtime) == c("POSIXct", "POSIXt")` — directly testing timestamp parsing.                                                |
| RunQuery applies schema appropriately            | [\#45](https://github.com/Gilead-BioStats/gsm.core/issues/45) | **Commit match.** Issue \#45 is “Feature: Support `logical` data type — map to BOOLEAN in duckdb.” The test includes `Tenured = list(type = "logical")` and asserts `class(result$Tenured) == "logical"` — directly testing logical type coercion.                                                                                        |
| RunQuery applies incomplete schema appropriately | [\#70](https://github.com/Gilead-BioStats/gsm.core/issues/70) | **Commit match.** Issue \#70 is “Update `RunQuery` to not set `character` type if not specified.” The test passes a `lColumnMapping` with one column that has no `type` field and asserts `class(result$emaN) == class(df$Name)` — verifying the original character type is preserved, not overridden with `character`.                   |
| RunQuery applies incomplete schema appropriately | [\#71](https://github.com/Gilead-BioStats/gsm.core/issues/71) | **Commit match.** Issue \#71 is “Bugfix: `RunQuery()` coerces undefined columns to `character`.” Same test as above; \#71 is the bug report underlying the \#70 business requirement. Both describe the same behavioral fix tested here.                                                                                                  |
| RunQuery parses invalid date/times correctly     | [\#44](https://github.com/Gilead-BioStats/gsm.core/issues/44) | **Commit match.** Issue \#44 is “Bugfix: `RunQuery` throws an error on empty `Date` strings.” The test passes `Birthday = c("1990JAN01", "1987-02-30", "")` and `Birthtime = c(...)` with invalid/empty values and asserts `all(is.na(result$Birthday))` and `all(is.na(result$Birthtime))` — exactly the `NA` behavior expected by \#44. |

------------------------------------------------------------------------

## test-RunStep.R

| Test                                            | Issue                                                         | Reason                                                                                                                                                                                                                                                                                                                                                 |
|-------------------------------------------------|---------------------------------------------------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Passes direct value vector parameters correctly | [\#23](https://github.com/Gilead-BioStats/gsm.core/issues/23) | **Commit match.** Issue \#23 is “Bugfix: Message out of `RunStep` related to vector arguments should not be vectorized — one message should be emitted for a vector-type argument.” The test uses `suppressMessages(expect_message(..., "y is of length 3"))` to confirm exactly one message is emitted for a 3-element vector, verifying the bug fix. |
| RunStep will run a function with no parameters  | [\#31](https://github.com/Gilead-BioStats/gsm.core/issues/31) | **Commit match.** Issue \#31 is “Feature/Bug — allow no params in workflow steps. Functions that have all defaults or no parameters currently fail.” The test calls `RunStep(list(name = "getwd"), list(), list())` with no `params` key and asserts the result equals `getwd()` — directly testing the fix.                                           |

------------------------------------------------------------------------

## test-util-checkSpec.R

| Test                       | Issue                                                         | Reason                                                                                                                                                                                                                                                                      |
|----------------------------|---------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Validate column type works | [\#22](https://github.com/Gilead-BioStats/gsm.core/issues/22) | **Commit match.** Issue \#22 adds support for `"timestamp"` as a recognized data type. The test spec includes `SnapshotDateTime = list(type = "timestamp")` and `expect_snapshot(CheckSpec(...))` to verify the spec check handles timestamp types correctly without error. |

------------------------------------------------------------------------

## test-util-MakeWorkflowList.R

| Test                                    | Issue                                                         | Reason                                                                                                                                                                                                                                                                                                                                      |
|-----------------------------------------|---------------------------------------------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| invalid data returns list NULL elements | [\#43](https://github.com/Gilead-BioStats/gsm.core/issues/43) | **Bonus round.** Issue \#43 is “`MakeWorkflowList` doesn’t work with packages that aren’t installed.” The test explicitly calls `MakeWorkflowList(strPackage = "fake-pkg", ...)` and wraps it in `expect_error()`, verifying that a non-existent package now produces a clear error rather than a cryptic `strPath does not exist` message. |

------------------------------------------------------------------------

## Skipped issues

The following closed issues were reviewed but no suitable test match was
found:

| Issue            | Title                                                         | Reason skipped                                                                                                 |
|------------------|---------------------------------------------------------------|----------------------------------------------------------------------------------------------------------------|
| \#1              | QC: Update ReadME                                             | Documentation only                                                                                             |
| \#2              | QC: Update vignettes                                          | Documentation only                                                                                             |
| \#7              | Feature: Add nMinNumerator to `Summarize()`                   | No test exercises `nMinNumerator`; `Summarize.R` shows `nMinDenominator` (deprecated) but not `nMinNumerator`. |
| \#8              | Feature: Add PK data to `lSource`                             | Data file change only                                                                                          |
| \#13             | QC: Update package data with PK updates                       | Data file change only                                                                                          |
| \#19             | QC: Add unit test for new parameter `vColumns` to `Summarize` | `vColumns` is not present in the current `Summarize()` signature; no test clearly maps to it.                  |
| \#24             | Bugfix: Fix outdated vignette features                        | Vignette only                                                                                                  |
| \#25             | Business Requirement: CRAN release of gsm.core                | Too broad; no specific behavior tested                                                                         |
| \#28             | Business Requirement: Update Accrual Thresholds               | YAML default changes; not tested in unit tests                                                                 |
| \#42             | Documentation: Update outdated links                          | Documentation only                                                                                             |
| \#47             | QC: Add a new example incorporating the delta columns         | Example/documentation only                                                                                     |
| \#50             | Feature: Update `lSource` to comply with `gsm.mapping@fix-72` | Data/example change only                                                                                       |
| \#56             | QC: update sample data                                        | Data update only                                                                                               |
| \#64             | Bugfix: `STUDCOMP` data bug from datasim                      | Data fix only                                                                                                  |
| \#66             | Call `Ingest` from `RunWorkflow`                              | RunWorkflow tests test happy-path outputs; none target Ingest specifically                                     |
| \#67             | Add `tryCatch` to `RunWorkflows`                              | No test for error-handling / tryCatch behavior in RunWorkflow                                                  |
| \#77 (qual_T5_2) | See above — **tagged**                                        | —                                                                                                              |
| \#79             | Update Contributor Guidelines                                 | Documentation only                                                                                             |
| \#80             | Add workflow tarball to releases                              | CI/CD only                                                                                                     |
| \#89             | Add site risk score metric to `reportingResults`              | Issue body is sparse; no unit test found that specifically targets this metric                                 |
| \#91             | Fix links to images in vignettes                              | Documentation only                                                                                             |
| \#96             | Add IE support in `.rda` files                                | Data file only                                                                                                 |
| \#101            | Refactor Examples                                             | Example/documentation only                                                                                     |
| \#104            | Update Readme.md                                              | Documentation only                                                                                             |
| \#105            | Incorporate `IE` into standard site-based KRI                 | No matching unit test found                                                                                    |
| \#107            | Implement gsm.utils v0.2.0 workflows                          | Workflow folder; no package code tested                                                                        |
| \#112            | Update Quality Control section of Readme                      | Documentation only                                                                                             |
| \#118            | Migrate qualification documentation                           | Documentation only                                                                                             |
| \#119            | Update r-releaser workflow                                    | CI/CD only                                                                                                     |
