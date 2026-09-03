## Test Setup
library(stringr)
kri_workflows <- flatten(workr::MakeWorkflowList(
  strNames = "kri0001",
  GetYamlPathMetrics()
))

outputs <- map_vec(kri_workflows$steps, ~ .x$output)

## Test Code
testthat::test_that("Qual: Given raw participant-level data, a properly specified Workflow for a KRI creates summarized and flagged data (#116)", {
  TestAtLogLevel("WARN")
  test <- robust_runworkflow(kri_workflows, mapped_data)
  # Transform_Rate drops groups whose total exposure is 0, so the analysis covers
  # mapped sites with a non-zero denominator rather than every mapped site.
  input_params <- kri_workflows$steps[[4]]$params
  expected_rows <- test$Mapped_SUBJ %>%
    filter(!is.na(.data[[input_params$strGroupCol]])) %>%
    group_by(GroupID = .data[[input_params$strGroupCol]]) %>%
    summarise(Denominator = sum(.data[[input_params$strDenominatorCol]])) %>%
    filter(.data$Denominator > 0) %>%
    nrow()

  # test output stucture
  expect_true(is.vector(test$vThreshold))
  expect_true(all(map_lgl(
    test[outputs[stringr::str_detect(outputs, pattern = "Analysis_")]],
    is.data.frame
  )))
  expect_equal(nrow(test$Analysis_Flagged), expected_rows)
  expect_equal(nrow(test$Analysis_Summary), expected_rows)

  # test output content
  expect_true(all(outputs %in% names(test)))
  flags <- test$Analysis_Flagged %>%
    mutate(
      hardcode_flag = case_when(
        Denominator < 30 ~ NA,
        Score <= test$vThreshold[1] ~ -2,
        Score > test$vThreshold[1] & Score <= test$vThreshold[2] ~ -1,
        Score >= test$vThreshold[3] & Score < test$vThreshold[4] ~ 1,
        Score >= test$vThreshold[4] ~ 2,
        TRUE ~ 0
      )
    ) %>%
    left_join(
      test$Analysis_Summary %>%
        select("GroupID", "Flag"),
      by = "GroupID"
    )

  expect_identical(flags$hardcode_flag, flags$Flag.x)
  expect_identical(flags$hardcode_flag, flags$Flag.y)

  expect_true(all(c("Weight", "WeightMax") %in% names(flags)))
})
