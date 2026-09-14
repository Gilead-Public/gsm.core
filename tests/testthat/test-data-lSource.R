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
