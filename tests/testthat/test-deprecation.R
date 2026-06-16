# Qualification test for gsm.core#149.
#
# The workflow-runtime functions were extracted to {workr}; {gsm.core} keeps
# deprecating shims so consumers can migrate without breakage. This test covers
# the issue's verification scenario: "calling any extracted function emits the
# lifecycle warning."

test_that("extracted workflow-runtime functions emit lifecycle deprecation warnings (#149)", {
  # Force lifecycle to warn on every call (defeat once-per-session rate limiting).
  withr::local_options(lifecycle_verbosity = "warning")

  # Each shim calls lifecycle::deprecate_warn() as its first statement, before
  # delegating to workr::. We only assert that the deprecation warning fires, so
  # any downstream error from the placeholder inputs is swallowed.
  swallow <- function(expr) tryCatch(expr, error = function(e) NULL)

  expect_warning(
    swallow(MakeWorkflowList()),
    class = "lifecycle_warning_deprecated"
  )
  expect_warning(
    swallow(RunQuery(strQuery = "SELECT 1", df = data.frame(x = 1))),
    class = "lifecycle_warning_deprecated"
  )
  expect_warning(
    swallow(RunStep(lStep = list(), lData = list(), lMeta = list())),
    class = "lifecycle_warning_deprecated"
  )
  expect_warning(
    swallow(RunWorkflow(lWorkflow = list())),
    class = "lifecycle_warning_deprecated"
  )
  expect_warning(
    swallow(RunWorkflows(lWorkflows = list())),
    class = "lifecycle_warning_deprecated"
  )
})
