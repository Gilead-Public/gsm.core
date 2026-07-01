#' Load workflows from a package/directory.
#'
#' @description
#' `r lifecycle::badge("deprecated")`
#'
#' `MakeWorkflowList()` has moved to `workr::MakeWorkflowList()`. This wrapper
#' remains for backward compatibility in `{gsm.core}`.
#'
#' @param strNames `array of character` List of workflows to include. NULL (the default) includes all workflows in the specified locations.
#' @param strPackage `character` The package name where the workflow YAML files are located. If NULL, the package will use an absolute path.
#' @param strPath `character` The location of workflow YAML files. If NULL (the default), function will look in `/inst/workflow` folder.
#' @param bExact `logical` Should strName matches be exact? If false, partial matches will be included. Default FALSE.
#' @param bRecursive `logical` Find files in nested folders? Default TRUE
#'
#' @examples
#' # get specific workflow files
#' workflow <- workr::MakeWorkflowList(
#'   strPath = "example_workflow/1_mappings",
#'   strPackage = "gsm.core"
#' )
#'
#' @return `list` A list of workflows with workflow and parameter metadata.
#'
#' @export

MakeWorkflowList <- function(
  strNames = NULL,
  strPath = "workflow",
  strPackage = NULL,
  bExact = FALSE,
  bRecursive = TRUE
) {
  lifecycle::deprecate_warn(
    when = "1.3.0",
    what = "gsm.core::MakeWorkflowList()",
    with = "workr::MakeWorkflowList()"
  )

  workr::MakeWorkflowList(
    strNames = strNames,
    strPath = strPath,
    strPackage = strPackage,
    bExact = bExact,
    bRecursive = bRecursive
  )
}
