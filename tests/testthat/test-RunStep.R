test_that("gsm.core::RunStep forwards to workr with a deprecation warning", {
  lStep <- list(name = "dummy_function", params = list(x = "lMeta", y = "lData"))
  lData <- list(data1 = 100)
  lMeta <- list(meta1 = 200)

  expected <- suppressMessages(workr::RunStep(lStep, lData, lMeta))

  expect_warning(
    result <- suppressMessages(gsm.core::RunStep(lStep, lData, lMeta)),
    "deprecated"
  )
  expect_equal(result, expected)
})
