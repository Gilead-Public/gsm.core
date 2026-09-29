test_that("lSource contains Raw_Death domain (#153)", {
  expect_true("Raw_Death" %in% names(lSource))
})

test_that("Raw_Death contains deathcls column (#153)", {
  expect_true("deathcls" %in% names(lSource$Raw_Death))
})

test_that("Raw_Death deathcls contains expected death reason values (#153, #156)", {
  # Full gsm.datasim deathcls generator vocabulary (see gsm.datasim R/Raw_Death.R).
  # The prior list held only the three reasons the pre-regen lSource happened to
  # sample; the IP non-starter regen shifts the RNG stream and can surface any of
  # the generator's reasons, so assert against the complete vocabulary.
  expected_values <- c(
    "Progressive Disease",
    "Adverse Event",
    "Disease Recurrence",
    "Not related to disease",
    "Related to long-term follow-up and not related to study drug"
  )
  actual_values <- unique(lSource$Raw_Death$deathcls)
  expect_true(all(actual_values %in% expected_values))
  expect_true(length(actual_values) > 1)
})

test_that("Raw_Death has required columns (#153)", {
  expected_cols <- c("studyid", "subjid", "death_dt", "deathcls")
  expect_true(all(expected_cols %in% names(lSource$Raw_Death)))
})

test_that("Raw_Death deathcls has no NA values (#153)", {
  expect_false(any(is.na(lSource$Raw_Death$deathcls)))
})

test_that("lSource carries the upstream IP non-starter fields (#177)", {
  drv <- c(
    "drv_enrollment_dt", "drv_ip_dosed", "drv_ip_first_dose_dt",
    "drv_enrl_first_dose_days", "drv_days_lapsed_since_enrl",
    "drv_ip_nonstarter_status"
  )
  expect_true(all(drv %in% names(lSource$Raw_SUBJ)))

  enrolled <- lSource$Raw_SUBJ[lSource$Raw_SUBJ$enrollyn == "Y", ]
  expect_true(all(enrolled$drv_ip_nonstarter_status %in% c(
    "Dosed", "Confirmed Non-Starter",
    "Potential Non-Starter outside window",
    "Potential Non-Starter within window"
  )))
})

test_that("lSource contains Raw_VS domain (#186)", {
  expect_true("Raw_VS" %in% names(lSource))
  expect_gt(nrow(lSource$Raw_VS), 0)
})

test_that("Raw_VS covers the six supported vital sign measures (#186)", {
  measures <- c("weight", "pulse", "sysbp", "diabp", "resp", "temp")
  expect_true(all(measures %in% names(lSource$Raw_VS)))
  performed <- lSource$Raw_VS[lSource$Raw_VS$vsperf_std == "Y", ]
  for (measure in measures) {
    expect_true(any(!is.na(performed[[measure]])), info = measure)
  }
})

test_that("Raw_VS has red, amber, and normal site bands of consecutive repeats (#186)", {
  # gsm.datasim (Gilead-Public/gsm.datasim#148) constructs per-site rates of
  # 3-long consecutive repeats: ~10% of sites "red" (45%), ~20% "amber" (25%),
  # the rest "normal" (5%). Missing values are dropped before windows form.
  site_repeat_rates <- function(measure, window = 3) {
    vs <- lSource$Raw_VS[!is.na(lSource$Raw_VS[[measure]]), ]
    vs <- vs[order(vs$subjid, vs$vs_dt), ]
    subj_sites <- unique(lSource$Raw_SUBJ[, c("subjid", "invid")])
    by_subject <- split(vs[[measure]], vs$subjid)
    counts <- vapply(by_subject, function(x) {
      n_windows <- length(x) - window + 1
      if (n_windows < 1) return(c(0, 0))
      repeats <- vapply(
        seq_len(n_windows),
        function(i) length(unique(x[i:(i + window - 1)])) == 1,
        logical(1)
      )
      c(sum(repeats), n_windows)
    }, numeric(2))
    site <- subj_sites$invid[match(colnames(counts), subj_sites$subjid)]
    tapply(counts[1, ], site, sum) / tapply(counts[2, ], site, sum)
  }

  measures <- c("weight", "pulse", "sysbp", "diabp", "resp", "temp")
  for (measure in measures) {
    rates <- site_repeat_rates(measure)
    pct_red <- mean(rates >= 0.35)
    pct_amber <- mean(rates >= 0.15 & rates < 0.35)
    expect_gt(pct_red, 0.05, label = paste(measure, "red share"))
    expect_lt(pct_red, 0.15, label = paste(measure, "red share"))
    expect_gt(pct_amber, 0.15, label = paste(measure, "amber share"))
    expect_lt(pct_amber, 0.25, label = paste(measure, "amber share"))
  }
})

test_that("Raw_SITE site IDs are unique and each site maps to one country (#186)", {
  # Guards against the site ID collision in Gilead-Public/gsm.datasim#167.
  expect_false(anyDuplicated(lSource$Raw_SITE$pi_number) > 0)
  subj_sites <- unique(lSource$Raw_SUBJ[, c("invid", "country")])
  expect_false(anyDuplicated(subj_sites$invid) > 0)
  site_country <- lSource$Raw_SITE$country[match(subj_sites$invid, lSource$Raw_SITE$pi_number)]
  expect_identical(subj_sites$country, site_country)
})
