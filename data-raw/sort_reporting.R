# Explicit sort keys for the bundled reporting data, so reruns don't produce
# row-order-only diffs and rows appear in a meaningful order. Sourced by
# simulate_longitudinal_data.R.

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
  ids <- sort(unique(id), method = "radix")
  core <- sub("^.*_", "", ids)
  prefix <- sub("[0-9].*$", "", core)
  num <- suppressWarnings(as.numeric(sub("^[^0-9]*([0-9]+).*$", "\\1", core)))
  suffix <- sub("^[^0-9]*[0-9]+", "", core)
  ord <- order(
    prefix == "srs", prefix, num, suffix, ids,
    method = "radix", na.last = TRUE
  )
  match(id, ids[ord])
}

sort_reporting_metrics <- function(x) {
  x[order(metric_rank(x$MetricID), method = "radix"), , drop = FALSE] |>
    `rownames<-`(NULL)
}

sort_reporting_results <- function(x) {
  x[order(
    x$GroupLevel, x$GroupID, -as.numeric(as.Date(x$SnapshotDate)),
    metric_rank(x$MetricID),
    method = "radix"
  ), , drop = FALSE] |>
    `rownames<-`(NULL)
}

sort_reporting_bounds <- function(x) {
  x[order(
    metric_rank(x$MetricID), -as.numeric(as.Date(x$SnapshotDate)),
    x$Threshold, x$Denominator,
    method = "radix"
  ), , drop = FALSE] |>
    `rownames<-`(NULL)
}

sort_reporting_groups <- function(x) {
  study_rank <- ifelse(
    x$GroupLevel == "Study",
    match(x$Param, study_param_order),
    NA_integer_
  )
  x[order(
    x$GroupLevel, x$GroupID, study_rank, tolower(x$Param), x$Param,
    method = "radix", na.last = TRUE
  ), , drop = FALSE] |>
    `rownames<-`(NULL)
}

sort_reporting <- function(x, name) {
  if (startsWith(name, "reportingMetrics")) return(sort_reporting_metrics(x))
  if (startsWith(name, "reportingResults")) return(sort_reporting_results(x))
  if (startsWith(name, "reportingBounds")) return(sort_reporting_bounds(x))
  if (startsWith(name, "reportingGroups")) return(sort_reporting_groups(x))
  # analytics*: unchanged from #202 (sort on every column, left to right).
  dplyr::arrange(x, dplyr::across(dplyr::everything()))
}
