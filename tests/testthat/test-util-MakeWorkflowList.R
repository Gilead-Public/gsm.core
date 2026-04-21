################################################################################

test_that("output is generated as expected", {
  wf_list <- MakeWorkflowList(strPath = test_path("testdata/mappings"))

  expect_true(is.list(wf_list))
  expect_true(all(map_chr(wf_list, ~ class(.)) == "list"))
  expect_snapshot(map(wf_list, ~ names(.)))
})

################################################################################

test_that("Metadata is returned as expected", {
  wf_list <- MakeWorkflowList(strPath = test_path("testdata/mappings"))
  expect_snapshot(map(wf_list, ~ .x$steps))
})

################################################################################

test_that("invalid data returns list NULL elements (#43)", {
  bRecursive <- TRUE
  ### strNames - testing strNames equal to random numeric array
  expect_snapshot(
    wf_list <- MakeWorkflowList(
      strNames = "kri8675309",
      strPath = test_path("testdata"),
      bRecursive = bRecursive
    )
  )
  expect_true(is.list(wf_list))
  expect_null(wf_list$kri8675309)

  ### strPath - testing strPath equal to non-existent/incorrect location of
  ### assessment YAML files
  expect_error(
    MakeWorkflowList(
      strPath = "beyonce",
      strPackage = NULL,
      bRecursive = bRecursive
    )
  )

  ### strPackage - testing strPackage equal to non-existent/incorrect package
  ### name
  expect_error(
    MakeWorkflowList(
      strPath = test_path("testdata/mappings"),
      strPackage = "fake-pkg",
      bRecursive = bRecursive
    )
  )

  ### bRecursive
  wf_list <- MakeWorkflowList(
    bRecursive = TRUE,
    strPath = test_path("testdata"),
    strNames = "kri0002"
  )$kri0002
  expect_true(is.list(wf_list))
  expect_length(wf_list, 4)
})

################################################################################

test_that("output is created as expected", {
  assessment_list <- MakeWorkflowList(strPath = test_path("testdata/mappings"))

  expect_snapshot(names(assessment_list))
  expect_type(assessment_list, "list")
  expect_true(all(map_lgl(assessment_list, ~ all(c("meta", "steps", "path") %in% names(.)))))
})
