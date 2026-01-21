## Test Setup
ae_workflow <- flatten(MakeWorkflowList(
  "kri0001b_custom",
  strPath = GetYamlPathCustomMetrics()
))

steps <- seq(1, length(ae_workflow$steps))

outputs <- map_vec(ae_workflow$steps[steps], ~ .x$output)

## Test Code
testthat::test_that("Qual: Given pre-processed input data, a properly specified Workflow for a KRI creates summarized and flagged data (#159)", {
  TestAtLogLevel("WARN")
  test <- robust_runworkflow(
    ae_workflow,
    list(Analysis_Input = gsm.core::analyticsInput),
    step = steps
  )
  expect_true(all(outputs %in% names(test)))
  expect_true(is.vector(test$vThreshold))
  expect_true(all(map_lgl(
    test[outputs[str_detect(outputs, pattern = "Analysis_")]],
    is.data.frame
  )))
  expect_equal(nrow(test$Analysis_Flagged), nrow(test$Analysis_Summary))
  expect_identical(
    sort(test$Analysis_Flagged$GroupID),
    sort(test$Analysis_Summary$GroupID)
  )
})
