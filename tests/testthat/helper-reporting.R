# Row of a reporting metrics table for one MetricID (#176).
metric_row <- function(metrics, id) metrics[metrics$MetricID == id, ]
