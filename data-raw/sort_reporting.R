# Explicit sort keys for the bundled reporting data, so reruns don't produce
# row-order-only diffs and rows appear in a meaningful order. Sourced by
# simulate_longitudinal_data.R.

library(dplyr)

# Curated Study Param order, taken from the pre-sort output in v1.3.1.
study_param_order <- c(
  "studyid", "nickname", "protocol_title", "status", "num_plan_site",
  "num_plan_subj", "act_fpfv", "est_fpfv", "est_lplv", "est_lpfv",
  "db_lock_dt", "therapeutic_area", "protocol_indication", "phase", "product",
  "SiteTarget", "ParticipantTarget", "ParticipantCount", "SiteCount",
  "PercentSitesActivated", "SiteActivation", "PercentParticipantsEnrolled",
  "ParticipantEnrollment"
)

# Rank MetricIDs naturally: kri0001 < kri0007 < kri0007-2 < kri0020a, with
# srs metrics last.
metric_rank <- function(id) {
  ids <- dplyr::tibble(id = unique(id)) |>
    dplyr::mutate(
      core = sub("^.*_", "", .data$id),
      prefix = sub("[0-9].*$", "", .data$core),
      num = suppressWarnings(
        as.numeric(sub("^[^0-9]*([0-9]+).*$", "\\1", .data$core))
      ),
      suffix = sub("^[^0-9]*[0-9]+", "", .data$core)
    ) |>
    dplyr::arrange(
      .data$prefix == "srs", .data$prefix, .data$num, .data$suffix, .data$id
    )
  match(id, ids$id)
}

sort_reporting_metrics <- function(x) {
  dplyr::arrange(x, metric_rank(.data$MetricID))
}

sort_reporting_results <- function(x) {
  dplyr::arrange(
    x,
    metric_rank(.data$MetricID),
    dplyr::desc(as.Date(.data$SnapshotDate)),
    .data$GroupLevel,
    .data$GroupID
  )
}

sort_reporting_bounds <- function(x) {
  dplyr::arrange(
    x,
    metric_rank(.data$MetricID),
    dplyr::desc(as.Date(.data$SnapshotDate)),
    .data$Threshold,
    .data$Denominator
  )
}

sort_reporting_groups <- function(x) {
  dplyr::arrange(
    x,
    .data$GroupLevel,
    .data$GroupID,
    # NA for non-Study rows, which then fall back to Param order.
    dplyr::if_else(
      .data$GroupLevel == "Study",
      match(.data$Param, study_param_order),
      NA_integer_
    ),
    tolower(.data$Param),
    .data$Param
  )
}

sort_reporting <- function(x, name) {
  if (startsWith(name, "reportingMetrics")) return(sort_reporting_metrics(x))
  if (startsWith(name, "reportingResults")) return(sort_reporting_results(x))
  if (startsWith(name, "reportingBounds")) return(sort_reporting_bounds(x))
  if (startsWith(name, "reportingGroups")) return(sort_reporting_groups(x))
  # analytics*: unchanged from #202 (sort on every column, left to right).
  dplyr::arrange(x, dplyr::across(dplyr::everything()))
}
