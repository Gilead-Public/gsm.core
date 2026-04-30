#' Convenience function to easily run multiple workflows
#'
#' @description
#' `r lifecycle::badge("deprecated")`
#'
#' `RunWorkflows()` has moved to `workr::RunWorkflows()`. This wrapper remains
#' for backward compatibility in `{gsm.core}`.
#'
#' @param lWorkflows `list` A named list of metadata defining how the workflow should be run.
#' @param lData `list` A named list of domain-level data frames.
#' @param lConfig `list` A configuration object with two methods:
#' - `LoadData`: A function that loads data specified in `lWorkflow$spec`.
#' - `SaveData`: A function that saves data returned by the last step in `lWorkflow$steps`.
#' @param bReturnResult `boolean` should *only* the result from the last step (`lResults`) be returned? If false, the full workflow (including `lResults`) is returned. Default is `TRUE`.
#' @param bKeepInputData `boolean` should the input data be included in `lData` after the workflow is run? Only relevant when bReturnResult is FALSE. Default is `TRUE`.
#' @param strResultNames `string` vector of length two, which describes the meta fields used to name the output.
#'
#' @return A named list of results from `RunWorkflow()`, where the names correspond to the names of
#' the workflow ID

#'
#' @export

RunWorkflows <- function(
  lWorkflows,
  lData = NULL,
  lConfig = NULL,
  bKeepInputData = FALSE,
  bReturnResult = TRUE,
  strResultNames = c("Type", "ID")
) {
  lifecycle::deprecate_warn(
    when = "1.3.0",
    what = "gsm.core::RunWorkflows()",
    with = "workr::RunWorkflows()"
  )

  workr::RunWorkflows(
    lWorkflows = lWorkflows,
    lData = lData,
    lConfig = lConfig,
    bKeepInputData = bKeepInputData,
    bReturnResult = bReturnResult,
    strResultNames = strResultNames
  )
}
