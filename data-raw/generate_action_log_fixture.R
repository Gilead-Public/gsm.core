# Generate a deterministic ActionLog fixture aligned with reportingResults.

freeze_action_log_lifecycle <- function(action_log) {
  extraction_order <- order(action_log$ExtractionDate)
  for (field in c("CreatedDate", "ResolvedDate", "ActionCreatedDate", "ActionResolvedDate")) {
    identifiers <- if (field == "CreatedDate") {
      action_log$RiskSignalID
    } else if (field == "ResolvedDate") {
      ifelse(is.na(action_log$ActionID), action_log$RiskSignalID, action_log$ActionID)
    } else {
      action_log$ActionID
    }
    keys <- paste(action_log$StudyID, identifiers, sep = "\r")
    present <- !is.na(identifiers) & !is.na(action_log[[field]])
    observed <- extraction_order[present[extraction_order]]
    first <- observed[!duplicated(keys[observed])]
    action_log[[field]][present] <- action_log[[field]][first][
      match(keys[present], keys[first])
    ]
  }
  end_date <- action_log$ExtractionDate
  resolved <- action_log$State %in% c("No Action", "Closed Action")
  end_date[resolved] <- action_log$ResolvedDate[resolved]
  action_log$RiskSignalAge <- as.numeric(end_date - action_log$SnapshotDate) + 1
  action_log
}

inputs <- gsm.core::action_log_testdata()
results <- inputs$reportingResults
results$SnapshotDate <- as.Date(results$SnapshotDate)

metrics <- inputs$reportingMetrics
groups <- inputs$reportingGroups

if (!requireNamespace("gsm.datasim", quietly = TRUE)) {
  stop(
    "Install gsm.datasim with ActionLog simulation support before regenerating this fixture.",
    call. = FALSE
  )
}

eligible <- results[
  results$GroupLevel == "Site" &
    grepl("^Analysis_kri", results$MetricID),
  c(
    "StudyID",
    "SnapshotDate",
    "GroupLevel",
    "GroupID",
    "MetricID",
    "Flag"
  ),
  drop = FALSE
]
eligible <- eligible[
  order(
    eligible$SnapshotDate,
    eligible$GroupID,
    eligible$MetricID
  ),
  ,
  drop = FALSE
]
row.names(eligible) <- NULL

metric_index <- match(eligible$MetricID, metrics$MetricID)
eligible$MetricLabel <- metrics$Metric[metric_index]
eligible$MetricAbbreviation <- metrics$Abbreviation[metric_index]

group_value <- function(param) {
  values <- groups[
    groups$GroupLevel == "Site" & groups$Param == param,
    c("GroupID", "Value"),
    drop = FALSE
  ]
  as.character(values$Value[match(eligible$GroupID, values$GroupID)])
}

eligible$GroupLabel <- group_value("InvestigatorLastName")
eligible$Country <- group_value("Country")

extraction_dates <- sort(unique(eligible$SnapshotDate))
extractions <- lapply(seq_along(extraction_dates), function(index) {
    extraction_date <- extraction_dates[index]
    frozen_results <- eligible[
      eligible$SnapshotDate <= extraction_date,
      ,
      drop = FALSE
    ]
    gsm.datasim::simulate_action_log_reviews(
      df_results = frozen_results,
      extraction_date = extraction_date,
      work_item_id_start = 900001L
    )
  })
reportingActionLog <- freeze_action_log_lifecycle(do.call(rbind, extractions))

group_labels <- unique(eligible[c("GroupID", "GroupLabel")])
reportingActionLog$GroupLabel <- group_labels$GroupLabel[
  match(reportingActionLog$GroupID, group_labels$GroupID)
]

write.csv(
  reportingActionLog,
  "data-raw/reportingActionLog.csv",
  row.names = FALSE,
  na = ""
)
save(reportingActionLog, file = "data/reportingActionLog.rda", compress = "xz")
