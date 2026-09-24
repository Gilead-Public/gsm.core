test_that("reportingActionLog has unique canonical scoring keys", {
  key <- c("StudyID", "SnapshotDate", "GroupLevel", "GroupID", "MetricID")

  expect_true(all(key %in% names(reportingActionLog)))
  expect_false(anyNA(reportingActionLog[key]))
  expect_false(anyDuplicated(reportingActionLog[key]) > 0L)
})

test_that("reportingActionLog aligns with flagged site KRI results", {
  key <- c("StudyID", "SnapshotDate", "GroupLevel", "GroupID", "MetricID")
  expected <- reportingResults[
    reportingResults$GroupLevel == "Site" &
      grepl("^Analysis_kri", reportingResults$MetricID) &
      !is.na(reportingResults$Flag) &
      reportingResults$Flag != 0,
    key,
    drop = FALSE
  ]

  make_key <- function(data) do.call(paste, c(data[key], sep = "\r"))
  expect_setequal(make_key(reportingActionLog), make_key(expected))
})

test_that("reportingActionLog contains valid longitudinal action metadata", {
  expect_s3_class(reportingActionLog$SnapshotDate, "Date")
  expect_s3_class(reportingActionLog$ExtractionDate, "Date")
  expect_true(all(reportingActionLog$ExtractionDate >= reportingActionLog$SnapshotDate))
  expect_setequal(
    unique(reportingActionLog$State),
    c("Awaiting Triage", "No Action", "Open Action", "Closed Action")
  )
  expect_false(any(reportingActionLog$RiskSignalDuplicateFlag))
  expect_true(length(unique(reportingActionLog$SnapshotDate)) > 1L)
})