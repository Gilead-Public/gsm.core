#' Run a single step in a workflow.
#'
#' @description
#' `r lifecycle::badge("deprecated")`
#'
#' `RunStep()` has moved to `workr::RunStep()`. This wrapper remains for
#' backward compatibility in `{gsm.core}`.
#'
#' @param lStep `list` single workflow step (typically pulled from `lWorkflow$steps`). Should
#'   include the name of the function to run (`lStep$name`), name of the object where the function result should be saved (`lStep$output`) and configurable parameters (`lStep$params`) (if any)
#' @param lData `list` a named list of domain level data frames.
#' @param lSpec `list` a data specification containing required columns. See the
#'  [gsm Extensions article](https://gilead-biostats.github.io/gsm.core/articles/gsmExtensions.html).
#' @param lMeta `list` a named list of meta data.
#'
#' @examples
#' wf_mapping <- workr::MakeWorkflowList(
#'   strNames = c("AE", "SUBJ"),
#'   strPath = "example_workflow/1_mappings",
#'   strPackage = "gsm.core",
#'   bExact = TRUE
#' )
#' lWorkflow <- workr::MakeWorkflowList(
#'   strPath = "example_workflow/2_metrics",
#'   strNames = c("kri0001", "kri0002"),
#'   strPackage = "gsm.core"
#' )
#' lStep <- lWorkflow[["kri0001"]][["steps"]][[1]]
#' lMeta <- lWorkflow[["kri0001"]][["meta"]]
#'
#' lRaw <- list(
#'   Raw_SUBJ = gsm.core::lSource$Raw_SUBJ,
#'   Raw_AE = gsm.core::lSource$Raw_AE
#' )
#'
#' mapped <- workr::RunWorkflows(wf_mapping, lRaw)
#' ae_step <- workr::RunStep(lStep = lStep, lData = mapped, lMeta = lMeta)
#'
#' @return `list` containing the results of the `lStep$name` function call should contain `.$checks`
#'   parameter with results from `is_mapping_vald` for each domain in `lStep$inputs`.
#'
#' @export

RunStep <- function(lStep, lData, lMeta, lSpec = NULL) {
  lifecycle::deprecate_warn(
    when = "1.3.0",
    what = "gsm.core::RunStep()",
    with = "workr::RunStep()"
  )

  workr::RunStep(
    lStep = lStep,
    lData = lData,
    lMeta = lMeta,
    lSpec = lSpec
  )
}
