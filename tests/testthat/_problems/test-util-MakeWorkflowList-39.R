# Extracted from test-util-MakeWorkflowList.R:39

# test -------------------------------------------------------------------------
bRecursive <- TRUE
expect_snapshot(
    wf_list <- workr::MakeWorkflowList(
      strNames = "kri8675309",
      strPath = test_path("testdata"),
      bRecursive = bRecursive
    )
  )
