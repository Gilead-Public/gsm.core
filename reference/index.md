# Package index

## Analyze

Conduct statistical analysis based on input data

- [`Analyze_NormalApprox()`](https://gilead-biostats.github.io/gsm.core/reference/Analyze_NormalApprox.md)
  **\[stable\]** : Funnel Plot Analysis with Normal Approximation for
  Binary and Rate Outcomes.
- [`Analyze_Identity()`](https://gilead-biostats.github.io/gsm.core/reference/Analyze_Identity.md)
  **\[stable\]** : Identity Analysis.
- [`Analyze_Fisher()`](https://gilead-biostats.github.io/gsm.core/reference/Analyze_Fisher.md)
  **\[stable\]** : Fisher's Exact Test Analysis.
- [`Analyze_Poisson()`](https://gilead-biostats.github.io/gsm.core/reference/Analyze_Poisson.md)
  **\[stable\]** : Poisson Analysis - Site Residuals.
- [`Analyze_NormalApprox_PredictBounds()`](https://gilead-biostats.github.io/gsm.core/reference/Analyze_NormalApprox_PredictBounds.md)
  **\[stable\]** : Funnel Plot Analysis with Normal Approximation -
  Predicted Boundaries.
- [`Analyze_Poisson_PredictBounds()`](https://gilead-biostats.github.io/gsm.core/reference/Analyze_Poisson_PredictBounds.md)
  **\[stable\]** : Poisson Analysis - Predicted Boundaries.

## Data Pipeline

Create site-level summary, analyzed, and flagged data for an assessment

- [`Input_Rate()`](https://gilead-biostats.github.io/gsm.core/reference/Input_Rate.md)
  **\[stable\]** : Input_Rate
- [`Transform_Count()`](https://gilead-biostats.github.io/gsm.core/reference/Transform_Count.md)
  **\[stable\]** : Transform Count
- [`Transform_Rate()`](https://gilead-biostats.github.io/gsm.core/reference/Transform_Rate.md)
  **\[stable\]** : Transform Rate
- [`Flag()`](https://gilead-biostats.github.io/gsm.core/reference/Flag.md)
  **\[stable\]** : Flag
- [`Flag_NormalApprox()`](https://gilead-biostats.github.io/gsm.core/reference/Flag_NormalApprox.md)
  **\[stable\]** : Flag_NormalApprox
- [`Flag_Poisson()`](https://gilead-biostats.github.io/gsm.core/reference/Flag_Poisson.md)
  **\[stable\]** : Flag_Poisson
- [`Summarize()`](https://gilead-biostats.github.io/gsm.core/reference/Summarize.md)
  **\[stable\]** : Make Summary Data Frame

## Utility

Utility functions for use within the Data Model

- [`cli_fmt()`](https://gilead-biostats.github.io/gsm.core/reference/cli_fmt.md)
  : cli style console appender for gsm
- [`CheckSpec()`](https://gilead-biostats.github.io/gsm.core/reference/CheckSpec.md)
  **\[stable\]** : Check if the data and spec are compatible
- [`GetStrFunctionIfNamespaced()`](https://gilead-biostats.github.io/gsm.core/reference/GetStrFunctionIfNamespaced.md)
  **\[experimental\]** : GetFunctionIfNamespaced
- [`LogMessage()`](https://gilead-biostats.github.io/gsm.core/reference/LogMessage.md)
  : Custom logging function that wraps cli messaging
- [`MakeWorkflowList()`](https://gilead-biostats.github.io/gsm.core/reference/MakeWorkflowList.md)
  **\[stable\]** : Load workflows from a package/directory.
- [`ParseThreshold()`](https://gilead-biostats.github.io/gsm.core/reference/ParseThreshold.md)
  **\[stable\]** : Parse a string into a numeric vector
- [`RunStep()`](https://gilead-biostats.github.io/gsm.core/reference/RunStep.md)
  **\[stable\]** : Run a single step in a workflow.
- [`RunQuery()`](https://gilead-biostats.github.io/gsm.core/reference/RunQuery.md)
  **\[stable\]** : Run a SQL query on a data frame or DuckDB table
- [`RunWorkflow()`](https://gilead-biostats.github.io/gsm.core/reference/RunWorkflow.md)
  **\[stable\]** : Run a workflow via it's YAML specification.
- [`RunWorkflows()`](https://gilead-biostats.github.io/gsm.core/reference/RunWorkflows.md)
  **\[stable\]** : Convenience function to easily run multiple workflows
- [`SetLogger()`](https://gilead-biostats.github.io/gsm.core/reference/SetLogger.md)
  : set the default package logger
- [`stop_if()`](https://gilead-biostats.github.io/gsm.core/reference/stop_if.md)
  : Custom stop message

## Sample Data

data used for examples and testing

- [`analyticsInput`](https://gilead-biostats.github.io/gsm.core/reference/analyticsInput.md)
  **\[stable\]** : analyticsInput Dataset
- [`analyticsSummary`](https://gilead-biostats.github.io/gsm.core/reference/analyticsSummary.md)
  **\[stable\]** : analyticsSummary Dataset
- [`reportingBounds`](https://gilead-biostats.github.io/gsm.core/reference/reportingBounds.md)
  **\[stable\]** : reportingBounds Dataset
- [`reportingGroups`](https://gilead-biostats.github.io/gsm.core/reference/reportingGroups.md)
  **\[stable\]** : reportingGroups Dataset
- [`reportingMetrics`](https://gilead-biostats.github.io/gsm.core/reference/reportingMetrics.md)
  **\[stable\]** : reportingMetrics Dataset
- [`reportingResults`](https://gilead-biostats.github.io/gsm.core/reference/reportingResults.md)
  **\[stable\]** : reportingResults Dataset
- [`reportingBounds_country`](https://gilead-biostats.github.io/gsm.core/reference/reportingBounds_country.md)
  **\[stable\]** : reportingBounds_country Dataset
- [`reportingGroups_country`](https://gilead-biostats.github.io/gsm.core/reference/reportingGroups_country.md)
  **\[stable\]** : reportingGroups_country Dataset
- [`reportingMetrics_country`](https://gilead-biostats.github.io/gsm.core/reference/reportingMetrics_country.md)
  **\[stable\]** : reportingMetrics_country Dataset
- [`reportingResults_country`](https://gilead-biostats.github.io/gsm.core/reference/reportingResults_country.md)
  **\[stable\]** : reportingResults_country Dataset
- [`reportingBounds_study`](https://gilead-biostats.github.io/gsm.core/reference/reportingBounds_study.md)
  **\[stable\]** : reportingBounds_study Dataset
- [`reportingGroups_study`](https://gilead-biostats.github.io/gsm.core/reference/reportingGroups_study.md)
  **\[stable\]** : reportingGroups_study Dataset
- [`reportingMetrics_study`](https://gilead-biostats.github.io/gsm.core/reference/reportingMetrics_study.md)
  **\[stable\]** : reportingMetrics_study Dataset
- [`reportingResults_study`](https://gilead-biostats.github.io/gsm.core/reference/reportingResults_study.md)
  **\[stable\]** : reportingResults_study Dataset
- [`lSource`](https://gilead-biostats.github.io/gsm.core/reference/lSource.md)
  **\[stable\]** : lSource Dataset
