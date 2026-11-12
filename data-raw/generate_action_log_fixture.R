# Generate a deterministic ActionLog fixture aligned with reportingResults.

results <- gsm.core::reportingResults
results$SnapshotDate <- as.Date(results$SnapshotDate)

metrics <- gsm.core::reportingMetrics
groups <- gsm.core::reportingGroups

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
reportingActionLog <- do.call(rbind, lapply(extractions, `[[`, "action_log"))
reportingActionLogExcludedSignals <- extractions[[length(extractions)]]$excluded_signals

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
write.csv(reportingActionLogExcludedSignals, "data-raw/reportingActionLogExcludedSignals.csv", row.names = FALSE, na = "")
save(reportingActionLogExcludedSignals, file = "data/reportingActionLogExcludedSignals.rda", compress = "xz")
