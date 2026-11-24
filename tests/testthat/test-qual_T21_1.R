## Test Setup
dist_workflow <- flatten(workr::MakeWorkflowList(
  strNames = "kri0001_dist_custom",
  strPath = GetYamlPathCustomMetrics()
))

# Expected configuration of kri0001_dist_custom.yaml, stated independently so
# that a change to the workflow is caught by the comparison below.
t21_config <- list(
  strGroupCol = "invid",
  strSubjectCol = "subjid",
  strNumeratorCatCols = c("aeser", "ae_flags"),
  strDenominatorCatCols = "drv_ip_nonstarter_status",
  strCatDelim = "|"
)
t21_single_value <- c("aeser", "drv_ip_nonstarter_status")

# Run the workflow once and reuse the result across tests.
run_dist_workflow <- local({
  result <- NULL
  function() {
    if (is.null(result)) {
      TestAtLogLevel("WARN")
      result <<- robust_runworkflow(dist_workflow, mapped_data)
    }
    result
  }
})

# Double-programmed distributions, derived from Mapped_* inputs.
expected_distributions <- function() {
  dfAE <- mapped_data$Mapped_AE %>%
    mutate(
      ae_flags = pmap_chr(
        list(aeser, aerel, aeongo),
        function(ser, rel, ongo) {
          paste(
            c("Serious", "Related", "Ongoing")[c(ser, rel, ongo) %in% "Y"],
            collapse = "|"
          )
        }
      )
    )

  qualification_input_rate_dist(
    dfSubjects = mapped_data$Mapped_SUBJ,
    dfNumerator = dfAE,
    dfDenominator = mapped_data$Mapped_SUBJ,
    strGroupCol = t21_config$strGroupCol,
    strSubjectCol = t21_config$strSubjectCol,
    strNumeratorCatCols = t21_config$strNumeratorCatCols,
    strDenominatorCatCols = t21_config$strDenominatorCatCols,
    strCatDelim = t21_config$strCatDelim
  )
}

group_input_totals <- function(dfInput) {
  dfInput %>%
    group_by(GroupID) %>%
    summarise(
      Numerator = sum(Numerator),
      Denominator = sum(Denominator),
      .groups = "drop"
    )
}

## Test Code
testthat::test_that("Qual: Given mapped data, a Workflow with an Input_Rate_Dist() step creates Analysis_Distributions with the expected structure (#214)", {
  skip_if_no_testdata()
  test <- run_dist_workflow()

  expect_s3_class(test$Analysis_Distributions, "data.frame")
  expect_named(
    test$Analysis_Distributions,
    c(
      "GroupID", "GroupLevel", "Source", "Variable", "Category",
      "Count", "Participants", "Total", "Percent"
    )
  )
  expect_true("Analysis_Distributions" %in% names(test$lAnalysis))

  variables <- test$Analysis_Distributions %>%
    distinct(Source, Variable) %>%
    arrange(Source, Variable)
  expect_equal(
    variables,
    tibble(
      Source = c("Denominator", "Numerator", "Numerator"),
      Variable = c("drv_ip_nonstarter_status", "ae_flags", "aeser")
    ),
    ignore_attr = TRUE
  )

  # Every group in the KRI input has distribution rows for every variable.
  groups_per_variable <- test$Analysis_Distributions %>%
    distinct(Source, Variable, GroupID) %>%
    count(Source, Variable)
  expect_true(all(
    groups_per_variable$n == n_distinct(test$Analysis_Input$GroupID)
  ))
})

testthat::test_that("Qual: Numerator distribution Total equals the KRI Numerator for each group (#214)", {
  skip_if_no_testdata()
  test <- run_dist_workflow()

  check <- test$Analysis_Distributions %>%
    filter(Source == "Numerator") %>%
    distinct(GroupID, Variable, Total) %>%
    left_join(group_input_totals(test$Analysis_Input), by = "GroupID")

  expect_gt(nrow(check), 0)
  expect_equal(check$Total, check$Numerator)
})

testthat::test_that("Qual: Denominator distribution Total equals the KRI Denominator for each group (#214)", {
  skip_if_no_testdata()
  test <- run_dist_workflow()

  check <- test$Analysis_Distributions %>%
    filter(Source == "Denominator") %>%
    distinct(GroupID, Variable, Total) %>%
    left_join(group_input_totals(test$Analysis_Input), by = "GroupID")

  expect_gt(nrow(check), 0)
  expect_equal(check$Total, check$Denominator)
})

testthat::test_that("Qual: For single-value variables, category Counts add up to Total; multi-value Counts can exceed it (#214)", {
  skip_if_no_testdata()
  test <- run_dist_workflow()

  sums <- test$Analysis_Distributions %>%
    group_by(Variable, GroupID) %>%
    summarise(Count = sum(Count), Total = first(Total), .groups = "drop")

  single <- filter(sums, Variable %in% t21_single_value)
  expect_equal(single$Count, single$Total)

  multi <- filter(sums, !Variable %in% t21_single_value)
  expect_true(all(multi$Count >= multi$Total))
  expect_true(any(multi$Count > multi$Total))
})

testthat::test_that("Qual: Count, Participants and Percent match independently derived distributions, including Not recorded and zero-filled categories (#214)", {
  skip_if_no_testdata()
  test <- run_dist_workflow()
  expected <- expected_distributions()

  # The data must exercise the edge cases being qualified.
  expect_true("Not recorded" %in% expected$Category)
  expect_true(any(expected$Count == 0))

  compare_cols <- c(
    "GroupID", "Source", "Variable", "Category",
    "Count", "Participants", "Total", "Percent"
  )
  sort_rows <- function(df) {
    df %>%
      select(all_of(compare_cols)) %>%
      arrange(Source, Variable, GroupID, Category)
  }

  expect_equal(
    sort_rows(test$Analysis_Distributions),
    sort_rows(expected),
    ignore_attr = TRUE
  )
  expect_true(all(test$Analysis_Distributions$GroupLevel == "Site"))
})
