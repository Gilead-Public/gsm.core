test_that("reporting metrics carry the kri0019/cou0019 count config (#180)", {
  kri <- reportingMetrics[reportingMetrics$MetricID == "Analysis_kri0019", ]
  cou <- reportingMetrics_country[
    reportingMetrics_country$MetricID == "Analysis_cou0019",
  ]

  expect_equal(c(kri$Model, cou$Model), c("Identity", "Identity"))
  expect_equal(c(kri$Threshold, cou$Threshold), c("1,2", "1,2"))
  expect_equal(kri$RiskScoreWeight, "0,4,8")
})

