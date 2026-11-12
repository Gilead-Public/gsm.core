test_that("reportingActionLog has unique identities within frozen extractions", {
  key <- c("StudyID", "SnapshotDate", "GroupLevel", "GroupID", "MetricID")
  identity <- c("ExtractionDate", "RiskSignalID", "ActionID")

  expect_true(all(key %in% names(reportingActionLog)))
  expect_false(anyNA(reportingActionLog[key]))
  expect_false(anyDuplicated(reportingActionLog[c(key, identity)]) > 0L)
  expect_true(anyDuplicated(reportingActionLog[c(key, "ExtractionDate")]) > 0L)
  expect_type(reportingActionLog$RiskSignalID, "character")
  expect_type(reportingActionLog$ActionID, "character")
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

test_that("reportingActionLog demonstrates proxy reviews and scoped quarantine", {
  expect_false("ActionedDate" %in% names(reportingActionLog))
  latest <- reportingResults[reportingResults$SnapshotDate == max(reportingResults$SnapshotDate), ]
  green <- latest[!is.na(latest$Flag) & latest$Flag == 0, ]
  reviewed <- merge(green, reportingActionLog[reportingActionLog$ExtractionDate == max(reportingActionLog$ExtractionDate), ],
    by = c("StudyID", "GroupLevel", "GroupID", "MetricID"), suffixes = c("_current", "_signal"))
  expect_gt(nrow(reviewed), 0L)
  expect_true(all(reviewed$State == "Closed Action"))
  expect_true(all(reviewed$SnapshotDate_signal < reviewed$SnapshotDate_current))
  audit <- reportingActionLogExcludedSignals
  expect_gt(nrow(audit), 0L)
  expect_type(audit$GroupID, "character")
  expect_true(all(is.na(audit$MetricID)))
  expect_s3_class(audit$SnapshotDate, "Date")
  expect_true(all(audit$GroupID %in% reportingActionLog$GroupID[reportingActionLog$State == "No Action"]))
})

test_that("reportingActionLog contains valid longitudinal action metadata", {
  expect_s3_class(reportingActionLog$SnapshotDate, "Date")
  expect_s3_class(reportingActionLog$ExtractionDate, "Date")
  expect_true(all(
    reportingActionLog$ExtractionDate >= reportingActionLog$SnapshotDate
  ))
  expect_setequal(
    unique(reportingActionLog$State),
    c("Awaiting Triage", "No Action", "Open Action", "Closed Action")
  )
  expect_false(any(reportingActionLog$RiskSignalDuplicateFlag))
  expect_true(length(unique(reportingActionLog$SnapshotDate)) > 1L)
  expect_equal(
    sort(unique(reportingActionLog$ExtractionDate)),
    sort(unique(reportingResults$SnapshotDate))
  )
  expect_true(anyNA(reportingActionLog$ActionID))
  expect_type(reportingActionLog$ActionCriticality, "logical")
  expect_true(all(
    c(
      "ActionURL",
      "ActionState",
      "RiskSignalState",
      "ActionCreatedDate",
      "ActionResolvedDate",
      "MetricType"
    ) %in%
      names(reportingActionLog)
  ))
  expect_equal(
    reportingActionLog$State,
    ifelse(
      is.na(reportingActionLog$ActionID),
      reportingActionLog$RiskSignalState,
      reportingActionLog$ActionState
    )
  )
})
