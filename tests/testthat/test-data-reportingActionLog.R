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

test_that("reportingActionLog uses synthetic organization URLs", {
  urls <- stats::na.omit(c(
    reportingActionLog$RiskSignalURL,
    reportingActionLog$ActionURL
  ))

  expect_gt(length(urls), 0L)
  expect_true(all(
    startsWith(urls, "https://dev.azure.com/example-org/") |
      startsWith(urls, "https://example.invalid/")
  ))
})

test_that("reportingActionLog aligns with flagged site KRI results", {
  results <- action_log_test_results()
  key <- c("StudyID", "SnapshotDate", "GroupLevel", "GroupID", "MetricID")
  expected <- results[
    results$GroupLevel == "Site" &
      grepl("^Analysis_kri", results$MetricID) &
      !is.na(results$Flag) &
      results$Flag != 0,
    key,
    drop = FALSE
  ]

  make_key <- function(data) do.call(paste, c(data[key], sep = "\r"))
  expect_setequal(make_key(reportingActionLog), make_key(expected))
})

test_that("reportingActionLog demonstrates proxy reviews", {
  results <- action_log_test_results()
  expect_false("ActionedDate" %in% names(reportingActionLog))
  latest <- results[results$SnapshotDate == max(results$SnapshotDate), ]
  green <- latest[!is.na(latest$Flag) & latest$Flag == 0, ]
  reviewed <- merge(green, reportingActionLog[reportingActionLog$ExtractionDate == max(reportingActionLog$ExtractionDate), ],
    by = c("StudyID", "GroupLevel", "GroupID", "MetricID"), suffixes = c("_current", "_signal"))
  expect_gt(nrow(reviewed), 0L)
  expect_true(all(reviewed$State == "Closed Action"))
  expect_true(all(reviewed$SnapshotDate_signal < reviewed$SnapshotDate_current))
})

test_that("reportingActionLog contains valid longitudinal action metadata", {
  results <- action_log_test_results()
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
    sort(unique(results$SnapshotDate))
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

test_that("frozen ActionLog reads retain identities and lifecycle dates", {
  signal_key <- with(reportingActionLog,
    paste(StudyID, SnapshotDate, GroupLevel, GroupID, MetricID))
  expect_true(all(vapply(split(reportingActionLog$RiskSignalID, signal_key),
    function(values) length(unique(values)) == 1L, logical(1))))
  for (field in c("CreatedDate", "ActionCreatedDate", "ActionResolvedDate")) {
    identifiers <- if (field == "CreatedDate") reportingActionLog$RiskSignalID else reportingActionLog$ActionID
    present <- !is.na(identifiers) & !is.na(reportingActionLog[[field]])
    keys <- paste(reportingActionLog$StudyID[present], identifiers[present])
    expect_true(all(vapply(split(reportingActionLog[[field]][present], keys),
      function(values) length(unique(values)) == 1L, logical(1))))
  }
  expect_true(all(is.na(reportingActionLog$CreatedDate) |
    reportingActionLog$CreatedDate <= reportingActionLog$ExtractionDate))
  expect_true(all(is.na(reportingActionLog$ActionCreatedDate) |
    reportingActionLog$ActionCreatedDate <= reportingActionLog$ExtractionDate))
})

test_that("ActionLog inputs use their own immutable release", {
  selected <- gsm$testdata_tag
  snapshot <- NULL
  testthat::local_mocked_bindings(
    gsm_testdata = function(...) list(cache = cachem::cache_mem(), snapshot = snapshot),
    .testdata_object_entry = function(tag, object) list(file = paste0(object, ".rds")),
    construct_fetcher = function(url_constructor, checksum_finder) {
      force(url_constructor)
      function(key) url_constructor(key)
    },
    .package = "gsm.core"
  )
  inputs <- action_log_testdata()
  expect_named(inputs, c("reportingResults", "reportingGroups", "reportingMetrics", "reportingBounds"))
  expect_true(all(grepl("/data-8cde53949d4d/", unlist(inputs), fixed = TRUE)))
  snapshot <- list(key = "unrelated-snapshot", dir = "not-used")
  expect_identical(action_log_testdata(), inputs)
  directory <- withr::local_tempdir()
  files <- stats::setNames(paste0(names(inputs), ".rds"), names(inputs))
  expected <- lapply(names(inputs), function(object) {
    value <- paste("matching", object)
    saveRDS(value, file.path(directory, files[[object]]))
    value
  })
  names(expected) <- names(inputs)
  write_snapshot_json(directory, objects = as.list(files),
    key = "sha256:8cde53949d4d7e1dcf3741905dbf42303a35ca96e662ea129306016c3a55572d")
  snapshot <- read_snapshot(directory)
  expect_identical(action_log_testdata(), expected)
  expect_identical(gsm$testdata_tag, selected)
})
