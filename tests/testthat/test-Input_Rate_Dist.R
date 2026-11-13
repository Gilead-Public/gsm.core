dist_subjects <- data.frame(
  SubjectID = c("S01", "S02", "S03", "S04", "S05"),
  GroupID = c("A", "A", "A", "B", "B")
)

test_that("Input_Rate argument checks still apply (#213)", {
  expect_error(Input_Rate_Dist(NULL, data.frame(), data.frame()))
  expect_error(Input_Rate_Dist(dist_subjects, dist_subjects, dist_subjects, strNumeratorMethod = "Invalid"))
  expect_error(Input_Rate_Dist(dist_subjects, dist_subjects, dist_subjects, strDenominatorMethod = "Sum"))
})

test_that("category columns that are not in the data stop with an error naming the column (#213)", {
  expect_error(
    Input_Rate_Dist(dist_subjects, dist_subjects, dist_subjects, strNumeratorCatCols = "eligibility_status"),
    "eligibility_status"
  )
  expect_error(
    Input_Rate_Dist(dist_subjects, dist_subjects, dist_subjects, strDenominatorCatCols = c("GroupID", "ip_status")),
    "ip_status"
  )
  expect_error(
    Input_Rate_Dist(dist_subjects, dist_subjects, dist_subjects, strNumeratorCatCols = 1),
    "strNumeratorCatCols"
  )
  expect_error(
    Input_Rate_Dist(dist_subjects, dist_subjects, dist_subjects, strDenominatorCatCols = ""),
    "strDenominatorCatCols"
  )
})

test_that("strCatDelim must be NULL or a single non-empty string (#213)", {
  for (delim in list("", NA_character_, c("|", ","), 1)) {
    expect_error(
      Input_Rate_Dist(dist_subjects, dist_subjects, dist_subjects, strNumeratorCatCols = "GroupID", strCatDelim = delim),
      "strCatDelim"
    )
  }
})

test_that("NULL category columns return an empty, correctly typed data frame (#213)", {
  result <- Input_Rate_Dist(dist_subjects, dist_subjects, dist_subjects)

  expect_equal(nrow(result), 0)
  expect_equal(
    names(result),
    c("GroupID", "GroupLevel", "Source", "Variable", "Category", "Count", "Participants", "Total", "Percent")
  )
  expect_type(result$GroupID, "character")
  expect_type(result$Category, "character")
  expect_type(result$Count, "double")
  expect_type(result$Participants, "integer")
  expect_type(result$Total, "double")
  expect_type(result$Percent, "double")
})

test_that("single-value breakdowns reconcile with Input_Rate totals (#213)", {
  dfDenominator <- dist_subjects %>%
    mutate(status = c("Eligible", "Ineligible", "Eligible", "Eligible", "Eligible"))
  dfNumerator <- data.frame(
    SubjectID = c("S01", "S01", "S02", "S04"),
    serious = c("Y", "N", "N", "N")
  )

  result <- Input_Rate_Dist(
    dist_subjects, dfNumerator, dfDenominator,
    strGroupLevel = "Site",
    strNumeratorCatCols = "serious",
    strDenominatorCatCols = "status"
  )

  dfTotals <- Input_Rate(dist_subjects, dfNumerator, dfDenominator) %>%
    group_by(GroupID) %>%
    summarise(Numerator = sum(Numerator), Denominator = sum(Denominator))

  dfCheck <- result %>%
    group_by(GroupID, Source, Variable) %>%
    summarise(Sum = sum(Count), Total = unique(Total), .groups = "drop") %>%
    left_join(dfTotals, by = "GroupID")

  expect_equal(dfCheck$Sum, dfCheck$Total)
  expect_equal(
    dfCheck$Total,
    ifelse(dfCheck$Source == "Numerator", dfCheck$Numerator, dfCheck$Denominator)
  )
  expect_equal(unique(result$GroupLevel), "Site")
  expect_equal(unique(result$Source), c("Numerator", "Denominator"))

  site_a_status <- result %>% filter(GroupID == "A", Variable == "status")
  expect_equal(site_a_status$Category, c("Eligible", "Ineligible"))
  expect_equal(site_a_status$Count, c(2, 1))
  expect_equal(site_a_status$Percent, c(2 / 3, 1 / 3))
})

test_that("multi-value cells are split, trimmed and de-duplicated, as in the worked example (#213)", {
  # kri0014, one site: 10 enrolled; S01 fails EXCL07 and INCL06; S02 fails EXCL07
  dfSubjects <- data.frame(SubjectID = sprintf("S%02d", 1:10), GroupID = "001")
  dfDenominator <- dfSubjects %>%
    mutate(eligibility_status = ifelse(SubjectID %in% c("S01", "S02"), "Ineligible", "Eligible"))
  dfNumerator <- data.frame(
    SubjectID = c("S01", "S02"),
    ietestcd_concat = c("EXCL07 | INCL06", "EXCL07|EXCL07")
  )

  result <- Input_Rate_Dist(
    dfSubjects, dfNumerator, dfDenominator,
    strNumeratorCatCols = "ietestcd_concat",
    strDenominatorCatCols = "eligibility_status",
    strCatDelim = "|"
  )

  num <- result %>% filter(Source == "Numerator")
  expect_equal(num$Category, c("EXCL07", "INCL06"))
  expect_equal(num$Count, c(2, 1))
  expect_equal(num$Participants, c(2L, 1L))
  expect_equal(num$Total, c(2, 2))
  expect_equal(num$Percent, c(1, 0.5))

  den <- result %>% filter(Source == "Denominator")
  expect_equal(den$Category, c("Eligible", "Ineligible"))
  expect_equal(den$Count, c(8, 2))
  expect_equal(den$Total, c(10, 10))
  expect_equal(den$Percent, c(0.8, 0.2))
})

test_that("missing and blank categories are reported as 'Not recorded' (#213)", {
  dfDenominator <- dist_subjects %>%
    mutate(status = c("Eligible", NA, "", "  ", "Eligible"))

  result <- Input_Rate_Dist(dist_subjects, dist_subjects, dfDenominator, strDenominatorCatCols = "status")

  expect_equal(unique(result$Category), c("Eligible", "Not recorded"))
  expect_equal(result$Count[result$GroupID == "A"], c(1, 2))
  expect_equal(result$Count[result$GroupID == "B"], c(1, 1))

  dfNumerator <- data.frame(SubjectID = c("S01", "S02"), reason = c(" | ", NA))
  result_delim <- Input_Rate_Dist(
    dist_subjects, dfNumerator, dist_subjects,
    strNumeratorCatCols = "reason", strCatDelim = "|"
  )
  expect_equal(unique(result_delim$Category), "Not recorded")
  expect_equal(result_delim$Count[result_delim$GroupID == "A"], 2)
})

test_that("every group gets every observed category, with zeros when absent (#213)", {
  dfNumerator <- data.frame(SubjectID = c("S01", "S02"), reason = c("AE", "Withdrew"))

  result <- Input_Rate_Dist(dist_subjects, dfNumerator, dist_subjects, strNumeratorCatCols = "reason")

  expect_equal(nrow(result), 4)
  site_b <- result %>% filter(GroupID == "B")
  expect_equal(site_b$Category, c("AE", "Withdrew"))
  expect_equal(site_b$Count, c(0, 0))
  expect_equal(site_b$Participants, c(0L, 0L))
  expect_equal(site_b$Total, c(0, 0))
  expect_true(all(is.na(site_b$Percent)))
})

test_that("Count counts records while Participants counts distinct subjects (#213)", {
  dfNumerator <- data.frame(
    SubjectID = c("S01", "S01", "S01", "S02"),
    category = c("Visit", "Visit", "Dosing", "Visit")
  )

  result <- Input_Rate_Dist(dist_subjects, dfNumerator, dist_subjects, strNumeratorCatCols = "category") %>%
    filter(GroupID == "A")

  expect_equal(result$Category, c("Dosing", "Visit"))
  expect_equal(result$Count, c(1, 3))
  expect_equal(result$Participants, c(1L, 2L))
  expect_equal(result$Total, c(4, 4))
})

test_that("Sum method sums the value column within each category (#213)", {
  dfDenominator <- dist_subjects %>%
    mutate(days = c(10, 20, NA, 5, 15), arm = c("X", "Y", "X", "X", "Y"))

  result <- Input_Rate_Dist(
    dist_subjects, dist_subjects, dfDenominator,
    strDenominatorMethod = "Sum", strDenominatorCol = "days",
    strDenominatorCatCols = "arm"
  )

  expect_equal(result$Count, c(10, 20, 5, 15))
  expect_equal(result$Total, c(30, 30, 20, 20))
})

test_that("records outside dfSubjects or without a group are dropped, as in Input_Rate (#213)", {
  dfSubjects <- dist_subjects %>% mutate(GroupID = c("A", "A", NA, "B", "B"))
  dfNumerator <- data.frame(SubjectID = c("S01", "S03", "S99"), reason = c("AE", "AE", "AE"))

  result <- suppressMessages(suppressWarnings(
    Input_Rate_Dist(dfSubjects, dfNumerator, dfSubjects, strNumeratorCatCols = "reason")
  ))

  expect_equal(result$GroupID, c("A", "B"))
  expect_equal(result$Count, c(1, 0))
  expect_equal(result$Total, c(1, 0))
})

test_that("multiple category columns are returned in order (#213)", {
  dfNumerator <- data.frame(SubjectID = "S01", window = "<=30 days", related = "Yes")

  result <- Input_Rate_Dist(
    dist_subjects, dfNumerator, dist_subjects,
    strNumeratorCatCols = c("window", "related")
  )

  expect_equal(unique(result$Variable), c("window", "related"))
})

test_that("works on lSource and reconciles with Input_Rate for every site (#213)", {
  skip_if_no_testdata()
  result <- Input_Rate_Dist(
    dfSubjects = gsm.core::lSource$Raw_SUBJ,
    dfNumerator = gsm.core::lSource$Raw_AE,
    dfDenominator = gsm.core::lSource$Raw_SUBJ,
    strSubjectCol = "subjid",
    strGroupCol = "invid",
    strGroupLevel = "Site",
    strNumeratorCatCols = "aeser",
    strDenominatorCatCols = "drv_ip_nonstarter_status"
  )

  dfInput <- Input_Rate(
    dfSubjects = gsm.core::lSource$Raw_SUBJ,
    dfNumerator = gsm.core::lSource$Raw_AE,
    dfDenominator = gsm.core::lSource$Raw_SUBJ,
    strSubjectCol = "subjid",
    strGroupCol = "invid",
    strGroupLevel = "Site"
  )

  expect_setequal(unique(result$GroupID), unique(dfInput$GroupID))

  dfCheck <- result %>%
    group_by(GroupID, Source) %>%
    summarise(Sum = sum(Count), Total = unique(Total), .groups = "drop")
  expect_equal(dfCheck$Sum, dfCheck$Total)
})
