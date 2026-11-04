test_that("gsm.core::RunQuery forwards to workr with a deprecation warning", {
  df <- data.frame(x = 1:3)
  query <- "SELECT * FROM df"

  expected <- suppressMessages(workr::RunQuery(query, df))

  expect_warning(
    result <- suppressMessages(gsm.core::RunQuery(query, df)),
    "deprecated"
  )
  expect_equal(result, expected)
})
