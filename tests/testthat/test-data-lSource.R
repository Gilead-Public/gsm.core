test_that("lSource contains Raw_Death domain (#153)", {
  expect_true("Raw_Death" %in% names(lSource))
})

test_that("Raw_Death contains deathcls column (#153)", {
  expect_true("deathcls" %in% names(lSource$Raw_Death))
})

test_that("Raw_Death deathcls contains expected death reason values (#153)", {
  expected_values <- c("Adverse Event", "Progressive Disease", "Disease Recurrence")
  actual_values <- unique(lSource$Raw_Death$deathcls)
  expect_true(all(actual_values %in% expected_values))
  expect_true(length(actual_values) > 1)
})

test_that("Raw_Death has required columns (#153)", {
  expected_cols <- c("studyid", "subjid", "death_dt", "deathcls")
  expect_true(all(expected_cols %in% names(lSource$Raw_Death)))
})

test_that("Raw_Death deathcls has no NA values (#153)", {
  expect_false(any(is.na(lSource$Raw_Death$deathcls)))
})
