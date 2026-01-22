testthat::test_that("Qual: Given raw participant-level data with missingness,
                    a properly specified Workflow for a KRI creates summarized and flagged data (#159)", {
  TestAtLogLevel("WARN")
  kri_workflows <- flatten(MakeWorkflowList(
    strNames = "kri0001",
    GetDefaultKRIPath()
  ))
  mapped_data_missing_values <- get_data(kri_workflows, lData_missing_values)

  outputs <- map_vec(kri_workflows$steps, ~ .x$output)
  test <- robust_runworkflow(kri_workflows, mapped_data_missing_values) %>%
    suppressWarnings()
  a <- capture_warnings(robust_runworkflow(
    kri_workflows,
    mapped_data_missing_values
  ))
  removed <- ifelse(
    length(a) == 0,
    0,
    a[2] %>%
      strsplit(., " ") %>%
      unlist() %>%
      dplyr::first() %>%
      str_extract(., "\\d+$") %>%
      as.numeric()
  )

  expected_rows <- length(na.omit(unique(test$Mapped_SUBJ[[
    kri_workflows$steps[[4]]$params$strGroupCol
  ]]))) -
    removed

  # test output stucture
  expect_true(is.vector(test$vThreshold))
  expect_true(all(map_lgl(
    test[outputs[str_detect(outputs, pattern = "Analysis_")]],
    is.data.frame
  )))
  expect_equal(nrow(test$Analysis_Flagged), expected_rows)
  expect_equal(nrow(test$Analysis_Summary), expected_rows)

  ## test
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
