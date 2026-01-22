test_that("workflow cache management works", {
  skip_if_not(requireNamespace("jsonlite", quietly = TRUE), "jsonlite not available")
  
  # Test cache directory creation
  cache_dir <- get_workflow_cache_dir()
  expect_true(dir.exists(cache_dir))
  
  # Test that we can check if cache needs update
  needs_update <- workflow_cache_needs_update()
  expect_type(needs_update, "logical")
})

test_that("cached workflow paths work with fallback", {
  # Test custom metrics path (should work with or without internet)
  metrics_path <- GetYamlPathCustomMetrics()
  expect_true(dir.exists(metrics_path))
  
  # Test mappings path (should work with or without internet) 
  mappings_path <- GetYamlPathMappings()
  expect_true(dir.exists(mappings_path))
})

test_that("force update parameter works", {
  skip_if_not(requireNamespace("jsonlite", quietly = TRUE), "jsonlite not available")
  
  # This should work even if we can't connect to GitHub
  # (will fall back to local files)
  expect_no_error({
    GetYamlPathCustomMetrics(force_update = TRUE)
  })
})

test_that("workflow files can be loaded from cache", {
  # Test that MakeWorkflowList works with cached paths
  metrics_path <- GetYamlPathCustomMetrics()
  
  if (dir.exists(metrics_path)) {
    # Should be able to find YAML files
    yaml_files <- list.files(metrics_path, pattern = "\\.ya?ml$", recursive = TRUE)
    
    if (length(yaml_files) > 0) {
      # Test that MakeWorkflowList can read the files
      workflows <- MakeWorkflowList(strPath = metrics_path)
      expect_type(workflows, "list")
    }
  }
})