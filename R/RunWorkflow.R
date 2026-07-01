#' Run a workflow via it's YAML specification.
#'
#' @description `r lifecycle::badge("deprecated")`
#' `RunWorkflow()` has moved to `workr::RunWorkflow()`. This wrapper remains
#' for backward compatibility in `{gsm.core}`.
#'
#' Attempts to run a single assessment (`lWorkflow`) using shared data (`lData`)
#' and metadata (`lMapping`). Calls `RunStep` for each item in
#' `lWorkflow$workflow` and saves the results to `lWorkflow`.
#'
#' @param lWorkflow `list` A named list of metadata defining how the workflow
#'   should be run.
#' @param lData `list` A named list of domain-level data frames.
#' @param lConfig `list` A configuration object with two methods:
#' - `LoadData`: A function that loads data specified in `lWorkflow$spec`.
#' - `SaveData`: A function that saves data returned by the last step in `lWorkflow$steps`.
#' @param bKeepInputData `boolean` should the input data be included in `lData`
#'   after the workflow is run? Only relevant when bReturnResult is FALSE.
#'   Default is `TRUE`.
#' @param bReturnResult `boolean` should *only* the result from the last step
#'   (`lResults`) be returned? If false, the full workflow (including
#'   `lResults`) is returned. Default is `TRUE`.
#'
#' @return Object containing the results of the workflow's last step (if
#'   `bLastResult` is `TRUE`) or the full workflow object (if `bReturnResults`
#'   is `TRUE`) or the full workflow object (if `bReturnResults` is `FALSE`).
#'
#' @examples
#' # Generate mapped input data to metric workflow.
#' lMappingWorkflows <- workr::MakeWorkflowList(
#'   strNames = c("AE", "SUBJ"),
#'   strPath = "example_workflow/1_mappings",
#'   strPackage = "gsm.core",
#'   bExact = TRUE
#' )
#' lRawData <- list(
#'   Raw_SUBJ = gsm.core::lSource$Raw_SUBJ,
#'   Raw_AE = gsm.core::lSource$Raw_AE
#' )
#'
#' lMappedData <- workr::RunWorkflows(
#'   lMappingWorkflows,
#'   lRawData
#' )
#'
#' # Run the metric workflow.
#' lMetricWorkflow <- workr::MakeWorkflowList(
#'   strPath = "example_workflow/2_metrics",
#'   strNames = c("kri0001", "kri0002"),
#'   strPackage = "gsm.core"
#' )$kri0001
#' lMetricOutput <- workr::RunWorkflow(
#'   lMetricWorkflow,
#'   lMappedData
#' )
#' @return `list` contains just lData if `bReturnData` is `TRUE`, otherwise returns the full `lWorkflow` object.
#'
#' @export

RunWorkflow <- function(
  lWorkflow,
  lData = NULL,
  lConfig = NULL,
  bReturnResult = TRUE,
  bKeepInputData = TRUE
) {
  lifecycle::deprecate_warn(
    when = "1.3.0",
    what = "gsm.core::RunWorkflow()",
    with = "workr::RunWorkflow()"
  )

  workr::RunWorkflow(
    lWorkflow = lWorkflow,
    lData = lData,
    lConfig = lConfig,
    bReturnResult = bReturnResult,
    bKeepInputData = bKeepInputData
  )
}
