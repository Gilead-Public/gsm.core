test_that("gsm.core::MakeWorkflowList forwards to workr with a deprecation warning", {
  expected <- suppressMessages(workr::MakeWorkflowList(strPath = test_path("testdata/mappings")))

  expect_warning(
    result <- suppressMessages(gsm.core::MakeWorkflowList(strPath = test_path("testdata/mappings"))),
    "deprecated"
  )
  expect_equal(result, expected)
})
