# Package-level state. Read as gsm$testdata_dir, gsm$testdata_handle,
# gsm$testdata_snapshots (named list of parsed snapshots, by tag),
# gsm$log_level, gsm$log_appender, etc.
gsm <- new.env(parent = emptyenv())

#' Parameters used in multiple functions
#'
#' @description Reused parameter definitions are gathered here for easier usage.
#'
#' @param dfBounds `data.frame` Set of predicted percentages/rates and upper-
#'   and lower-bounds across the full range of sample sizes/total exposure
#'   values for reporting. Expected columns: `Threshold`, `Denominator`,
#'   `Numerator`, `Metric`, `MetricID`, `StudyID`, `SnapshotDate`.
#' @param dfInput `data.frame` Input data with one record per subject. Created
#'   by passing Raw+ data into [Input_Rate()]. Expected columns: `GroupID`,
#'   `GroupLevel`, `Numerator`, `Denominator` and/or columns specified in
#'   `strCountCol` and `strGroupCol`.
#' @param lParamLabels `list` Labels for parameters, with the parameters as
#'   names, and the label as value.
#' @param bDebug `logical` Print debug messages? Default: `FALSE`.
#'
#'
#' @name shared-params
#' @keywords internal
NULL
