# Qualification test for gsm.core#149.
#
# The workflow-runtime functions were extracted to {workr}; {gsm.core} keeps
# deprecating shims so consumers can migrate without breakage. This test covers
# the issue's verification scenario: "calling any extracted function emits the
# lifecycle warning."

test_that("extracted workflow-runtime functions emit lifecycle deprecation warnings (#149)", {
  # Each shim calls lifecycle::deprecate_warn() as its first statement, before
  # delegating to workr::. We only assert that the deprecation warning fires, so
  # any downstream error from the placeholder inputs is swallowed.
  swallow <- function(expr) tryCatch(expr, error = function(e) NULL)

  lifecycle::expect_deprecated(
    swallow(MakeWorkflowList())
  )
  lifecycle::expect_deprecated(
    swallow(RunQuery(strQuery = "SELECT 1", df = data.frame(x = 1)))
  )
  lifecycle::expect_deprecated(
    swallow(RunStep(lStep = list(), lData = list(), lMeta = list()))
  )
  lifecycle::expect_deprecated(
    swallow(RunWorkflow(lWorkflow = list()))
  )
  lifecycle::expect_deprecated(
    swallow(RunWorkflows(lWorkflows = list()))
  )
})
