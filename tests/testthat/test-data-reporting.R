test_that("reporting metrics carry the kri0019/cou0019 count config (#180)", {
  kri <- reportingMetrics[reportingMetrics$MetricID == "Analysis_kri0019", ]
  cou <- reportingMetrics_country[
    reportingMetrics_country$MetricID == "Analysis_cou0019",
  ]

  expect_equal(c(kri$Model, cou$Model), c("Identity", "Identity"))
  expect_equal(c(kri$Threshold, cou$Threshold), c("1,2", "1,2"))
  expect_equal(kri$RiskScoreWeight, "0,4,8")
})

# ---- Premature treatment discontinuation (#176) ----
metric_row <- function(metrics, id) metrics[metrics$MetricID == id, ]

test_that("kri0007-2/cou0007-2 read Premature Treatment Discontinuation Rate and stay inactive (#176)", {
  kri <- metric_row(reportingMetrics, "Analysis_kri0007-2")
  cou <- metric_row(reportingMetrics_country, "Analysis_cou0007-2")

  expect_equal(c(kri$Abbreviation, cou$Abbreviation), c("PTDC", "PTDC"))
  expect_equal(
    c(kri$Metric, cou$Metric),
    rep("Premature Treatment Discontinuation Rate", 2)
  )
  # Inactive rows are left out of the site risk score.
  expect_equal(as.logical(c(kri$Active, cou$Active)), c(FALSE, FALSE))
})

test_that("kri0007/cou0007 keep Treatment Discontinuation Rate (#176)", {
  kri <- metric_row(reportingMetrics, "Analysis_kri0007")
  cou <- metric_row(reportingMetrics_country, "Analysis_cou0007")

  expect_equal(c(kri$Abbreviation, cou$Abbreviation), c("TDSC", "TDSC"))
})

test_that("latest kri0007-2/cou0007-2 counts equal the dosed and discontinued subjects in lSource (#176)", {
  subj <- lSource$Raw_SUBJ
  dosed <- subj[subj$enrollyn %in% "Y" & subj$drv_ip_dosed %in% "Y", ]
  check <- function(results, id, col) {
    got <- results[
      results$MetricID == id &
        results$SnapshotDate == max(results$SnapshotDate),
    ]
    want <- dplyr::summarise(
      dplyr::group_by(dosed, GroupID = .data[[col]]),
      Numerator = sum(!is.na(.data$drv_treatment_discontinuation_dt)),
      Denominator = dplyr::n()
    )
    expect_setequal(got$GroupID, want$GroupID)
    got <- got[match(want$GroupID, got$GroupID), ]
    expect_equal(got$Numerator, want$Numerator)
    expect_equal(got$Denominator, want$Denominator)
  }

  check(reportingResults, "Analysis_kri0007-2", "invid")
  check(reportingResults_country, "Analysis_cou0007-2", "country")
})

test_that("at least one kri0007-2 site is flagged (#176)", {
  flags <- reportingResults$Flag[
    reportingResults$MetricID == "Analysis_kri0007-2"
  ]

  expect_true(any(abs(flags) %in% c(1, 2)))
})
