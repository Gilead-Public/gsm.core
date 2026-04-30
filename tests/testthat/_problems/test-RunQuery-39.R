# Extracted from test-RunQuery.R:39

# setup ------------------------------------------------------------------------
library(testthat)
test_env <- simulate_test_env(package = "gsm.core", path = "..")
attach(test_env, warn.conflicts = FALSE)

# test -------------------------------------------------------------------------
df <- data.frame()
query <- "SELECT * FROM df WHERE Age >= 30"
expect_warning(
    result <- RunQuery(query, df),
    regexp = "empty data frame"
  )
