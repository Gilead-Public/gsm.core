# Generate a deterministic ActionLog fixture aligned with reportingResults.

results <- read.csv(
  "data-raw/reportingResults.csv",
  colClasses = c(GroupID = "character"),
  stringsAsFactors = FALSE
)
results$SnapshotDate <- as.Date(results$SnapshotDate)

metrics <- read.csv(
  "data-raw/reportingMetrics.csv",
  stringsAsFactors = FALSE
)
groups <- read.csv(
  "data-raw/reportingGroups.csv",
  colClasses = c(GroupID = "character"),
  stringsAsFactors = FALSE
)

eligible <- results[
  results$GroupLevel == "Site" &
    grepl("^Analysis_kri", results$MetricID) &
    !is.na(results$Flag) &
    results$Flag != 0,
  c("StudyID", "SnapshotDate", "GroupLevel", "GroupID", "MetricID"),
  drop = FALSE
]
eligible <- eligible[order(
  eligible$SnapshotDate,
  eligible$GroupID,
  eligible$MetricID
), , drop = FALSE]
row.names(eligible) <- NULL

history_key <- paste(eligible$GroupID, eligible$MetricID, sep = "\r")
history_index <- ave(seq_along(history_key), history_key, FUN = seq_along)
history_bucket <- vapply(
  strsplit(history_key, "", fixed = TRUE),
  function(chars) sum(utf8ToInt(paste(chars, collapse = ""))) %% 4L,
  integer(1)
)

eligible$State <- ifelse(
  history_bucket == 0L,
  "No Action",
  ifelse(
    history_bucket == 1L,
    ifelse(history_index == 1L, "Awaiting Triage", "Open Action"),
    ifelse(
      history_bucket == 2L,
      ifelse(history_index == 1L, "Open Action", "Closed Action"),
      "Awaiting Triage"
    )
  )
)

metric_index <- match(eligible$MetricID, metrics$MetricID)
metric_label <- metrics$Metric[metric_index]
metric_abbreviation <- metrics$Abbreviation[metric_index]

group_value <- function(param) {
  values <- groups[
    groups$GroupLevel == "Site" & groups$Param == param,
    c("GroupID", "Value"),
    drop = FALSE
  ]
  as.character(values$Value[match(eligible$GroupID, values$GroupID)])
}

resolved <- eligible$State %in% c("No Action", "Closed Action")
created_date <- eligible$SnapshotDate + 1L
resolved_date <- as.Date(rep(NA_character_, nrow(eligible)))
resolved_date[resolved] <- eligible$SnapshotDate[resolved] + 7L
extraction_date <- eligible$SnapshotDate + 14L

relevant_date <- as.Date(rep(NA_character_, nrow(eligible)))
for (key in unique(history_key)) {
  indexes <- which(history_key == key)
  states <- eligible$State[indexes]
  dates <- eligible$SnapshotDate[indexes]
  selected <- if (any(states == "Open Action")) {
    min(dates[states == "Open Action"])
  } else if (any(states == "Closed Action")) {
    max(dates[states == "Closed Action"])
  } else if (any(states == "Awaiting Triage")) {
    min(dates[states == "Awaiting Triage"])
  } else {
    min(dates)
  }
  relevant_date[indexes] <- selected
}

age_end_date <- extraction_date
age_end_date[resolved] <- resolved_date[resolved]

reportingActionLog <- data.frame(
  StudyID = eligible$StudyID,
  SnapshotDate = eligible$SnapshotDate,
  GroupLevel = eligible$GroupLevel,
  GroupID = eligible$GroupID,
  MetricID = eligible$MetricID,
  State = eligible$State,
  AssignedTo = ifelse(
    eligible$State %in% c("Open Action", "Closed Action"),
    "Synthetic Monitor",
    NA_character_
  ),
  RiskSignalID = seq.int(900001L, length.out = nrow(eligible)),
  RiskSignalURL = paste0(
    "https://example.invalid/risk-signals/",
    seq.int(900001L, length.out = nrow(eligible))
  ),
  SignalDescription = paste(metric_label, "requires review at site", eligible$GroupID),
  RecommendedAction = "Review the synthetic risk signal.",
  ActionTaken = ifelse(
    eligible$State == "Closed Action",
    "Synthetic review completed.",
    NA_character_
  ),
  CTMSID = NA_character_,
  CreatedDate = created_date,
  ResolvedDate = resolved_date,
  ExtractionDate = extraction_date,
  RiskSignalDuplicateFlag = FALSE,
  RelevantSnapshotDate = relevant_date,
  RelevantSnapshotFlag = relevant_date == eligible$SnapshotDate,
  RiskSignalAge = as.numeric(age_end_date - eligible$SnapshotDate) + 1,
  FunctionalArea = "Central Monitoring",
  GroupLabel = group_value("InvestigatorLastName"),
  MetricLabel = metric_label,
  MetricAbbreviation = metric_abbreviation,
  Country = group_value("Country"),
  stringsAsFactors = FALSE,
  check.names = FALSE
)

write.csv(
  reportingActionLog,
  "data-raw/reportingActionLog.csv",
  row.names = FALSE,
  na = ""
)