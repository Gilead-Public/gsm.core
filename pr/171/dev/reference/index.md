# Package index

## Analyze

Conduct statistical analysis based on input data

- [`Analyze_NormalApprox()`](https://gilead-biostats.github.io/gsm.core/dev/reference/Analyze_NormalApprox.md)
  **\[stable\]** : Funnel Plot Analysis with Normal Approximation for
  Binary and Rate Outcomes.
- [`Analyze_Identity()`](https://gilead-biostats.github.io/gsm.core/dev/reference/Analyze_Identity.md)
  **\[stable\]** : Identity Analysis.
- [`Analyze_Fisher()`](https://gilead-biostats.github.io/gsm.core/dev/reference/Analyze_Fisher.md)
  **\[stable\]** : Fisher's Exact Test Analysis.
- [`Analyze_Poisson()`](https://gilead-biostats.github.io/gsm.core/dev/reference/Analyze_Poisson.md)
  **\[stable\]** : Poisson Analysis - Site Residuals.
- [`Analyze_NormalApprox_PredictBounds()`](https://gilead-biostats.github.io/gsm.core/dev/reference/Analyze_NormalApprox_PredictBounds.md)
  **\[stable\]** : Funnel Plot Analysis with Normal Approximation -
  Predicted Boundaries.
- [`Analyze_Poisson_PredictBounds()`](https://gilead-biostats.github.io/gsm.core/dev/reference/Analyze_Poisson_PredictBounds.md)
  **\[stable\]** : Poisson Analysis - Predicted Boundaries.

## Data Pipeline

Create site-level summary, analyzed, and flagged data for an assessment

- [`Input_Rate()`](https://gilead-biostats.github.io/gsm.core/dev/reference/Input_Rate.md)
  **\[stable\]** : Input_Rate
- [`Transform_Count()`](https://gilead-biostats.github.io/gsm.core/dev/reference/Transform_Count.md)
  **\[stable\]** : Transform Count
- [`Transform_Rate()`](https://gilead-biostats.github.io/gsm.core/dev/reference/Transform_Rate.md)
  **\[stable\]** : Transform Rate
- [`Flag()`](https://gilead-biostats.github.io/gsm.core/dev/reference/Flag.md)
  **\[stable\]** : Flag
- [`Flag_NormalApprox()`](https://gilead-biostats.github.io/gsm.core/dev/reference/Flag_NormalApprox.md)
  **\[stable\]** : Flag_NormalApprox
- [`Flag_Poisson()`](https://gilead-biostats.github.io/gsm.core/dev/reference/Flag_Poisson.md)
  **\[stable\]** : Flag_Poisson
- [`Summarize()`](https://gilead-biostats.github.io/gsm.core/dev/reference/Summarize.md)
  **\[stable\]** : Make Summary Data Frame

## Utility

Utility functions for use within the Data Model

- [`cli_fmt()`](https://gilead-biostats.github.io/gsm.core/dev/reference/cli_fmt.md)
  : cli-style console appender for gsm
- [`CheckSpec()`](https://gilead-biostats.github.io/gsm.core/dev/reference/CheckSpec.md)
  **\[stable\]** : Check if the data and spec are compatible
- [`GetLogAppender()`](https://gilead-biostats.github.io/gsm.core/dev/reference/GetLogAppender.md)
  : Get the current log appender function
- [`GetLogLevel()`](https://gilead-biostats.github.io/gsm.core/dev/reference/GetLogLevel.md)
  : Get the current logging threshold level
- [`GetStrFunctionIfNamespaced()`](https://gilead-biostats.github.io/gsm.core/dev/reference/GetStrFunctionIfNamespaced.md)
  **\[experimental\]** : GetFunctionIfNamespaced
- [`LogMessage()`](https://gilead-biostats.github.io/gsm.core/dev/reference/LogMessage.md)
  : Log a message via the active appender
- [`MakeWorkflowList()`](https://gilead-biostats.github.io/gsm.core/dev/reference/MakeWorkflowList.md)
  **\[deprecated\]** : Load workflows from a package/directory.
- [`ParseThreshold()`](https://gilead-biostats.github.io/gsm.core/dev/reference/ParseThreshold.md)
  **\[stable\]** : Parse a string into a numeric vector
- [`RunStep()`](https://gilead-biostats.github.io/gsm.core/dev/reference/RunStep.md)
  **\[deprecated\]** : Run a single step in a workflow.
- [`RunQuery()`](https://gilead-biostats.github.io/gsm.core/dev/reference/RunQuery.md)
  **\[deprecated\]** : Run a SQL query on a data frame or DuckDB table
- [`RunWorkflow()`](https://gilead-biostats.github.io/gsm.core/dev/reference/RunWorkflow.md)
  **\[deprecated\]** : Run a workflow via it's YAML specification.
- [`RunWorkflows()`](https://gilead-biostats.github.io/gsm.core/dev/reference/RunWorkflows.md)
  **\[deprecated\]** : Convenience function to easily run multiple
  workflows
- [`SetLogger()`](https://gilead-biostats.github.io/gsm.core/dev/reference/SetLogger.md)
  : Set the logging threshold level
- [`SetLogAppender()`](https://gilead-biostats.github.io/gsm.core/dev/reference/SetLogAppender.md)
  : Set the active log appender
- [`SetLogLevel()`](https://gilead-biostats.github.io/gsm.core/dev/reference/SetLogLevel.md)
  : Set the active log level
- [`stop_if()`](https://gilead-biostats.github.io/gsm.core/dev/reference/stop_if.md)
  : Stop execution if a condition is true

## Sample Data

data used for examples and testing

- [`analyticsInput`](https://gilead-biostats.github.io/gsm.core/dev/reference/analyticsInput.md)
  **\[stable\]** : analyticsInput Dataset
- [`analyticsSummary`](https://gilead-biostats.github.io/gsm.core/dev/reference/analyticsSummary.md)
  **\[stable\]** : analyticsSummary Dataset
- [`reportingBounds`](https://gilead-biostats.github.io/gsm.core/dev/reference/reportingBounds.md)
  **\[stable\]** : reportingBounds Dataset
- [`reportingGroups`](https://gilead-biostats.github.io/gsm.core/dev/reference/reportingGroups.md)
  **\[stable\]** : reportingGroups Dataset
- [`reportingMetrics`](https://gilead-biostats.github.io/gsm.core/dev/reference/reportingMetrics.md)
  **\[stable\]** : reportingMetrics Dataset
- [`reportingResults`](https://gilead-biostats.github.io/gsm.core/dev/reference/reportingResults.md)
  **\[stable\]** : reportingResults Dataset
- [`reportingBounds_country`](https://gilead-biostats.github.io/gsm.core/dev/reference/reportingBounds_country.md)
  **\[stable\]** : reportingBounds_country Dataset
- [`reportingGroups_country`](https://gilead-biostats.github.io/gsm.core/dev/reference/reportingGroups_country.md)
  **\[stable\]** : reportingGroups_country Dataset
- [`reportingMetrics_country`](https://gilead-biostats.github.io/gsm.core/dev/reference/reportingMetrics_country.md)
  **\[stable\]** : reportingMetrics_country Dataset
- [`reportingResults_country`](https://gilead-biostats.github.io/gsm.core/dev/reference/reportingResults_country.md)
  **\[stable\]** : reportingResults_country Dataset
- [`reportingBounds_study`](https://gilead-biostats.github.io/gsm.core/dev/reference/reportingBounds_study.md)
  **\[stable\]** : reportingBounds_study Dataset
- [`reportingGroups_study`](https://gilead-biostats.github.io/gsm.core/dev/reference/reportingGroups_study.md)
  **\[stable\]** : reportingGroups_study Dataset
- [`reportingMetrics_study`](https://gilead-biostats.github.io/gsm.core/dev/reference/reportingMetrics_study.md)
  **\[stable\]** : reportingMetrics_study Dataset
- [`reportingResults_study`](https://gilead-biostats.github.io/gsm.core/dev/reference/reportingResults_study.md)
  **\[stable\]** : reportingResults_study Dataset
- [`lSource`](https://gilead-biostats.github.io/gsm.core/dev/reference/lSource.md)
  **\[stable\]** : lSource Dataset
