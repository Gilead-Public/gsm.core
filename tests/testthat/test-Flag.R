test_that("Flag function works correctly with z-score data", {
  dfAnalyzed <- data.frame(
    GroupID = 1:12,
    Score = c(-4, -3.1, -3, -2.9, -2.1, -2, -1.9, 0, 2, 2.9, 3, 3.1)
  )

  # unsorted
  dfFlagged <- Flag(dfAnalyzed, vFlagOrder = NULL)
  expect_equal(dfFlagged$Flag, c(-2, -2, -1, -1, -1, 0, 0, 0, 1, 1, 2, 2))

  # sorted
  expect_message(
    {
      dfFlagged <- Flag(dfAnalyzed)
    },
    "Sorted dfFlagged using custom Flag order"
  )
  expect_equal(dfFlagged$Flag, c(2, 2, -2, -2, 1, 1, -1, -1, -1, 0, 0, 0))

  # Test with custom thresholds and flags
  dfFlagged <- Flag(dfAnalyzed, vThreshold = c(-2, 2), vFlag = c(-1, 0, 1), vFlagOrder = NULL)
  expect_equal(dfFlagged$Flag, c(-1, -1, -1, -1, -1, 0, 0, 0, 1, 1, 1, 1))

  # Test Alias
  dfFlagged <- Flag_NormalApprox(dfAnalyzed, vFlagOrder = NULL)
  expect_equal(dfFlagged$Flag, c(-2, -2, -1, -1, -1, 0, 0, 0, 1, 1, 2, 2))
})

test_that("Flag function works correctly with rate data", {
  # Test with rate data
  dfAnalyzed_Rate <- data.frame(
    GroupID = 1:9,
    Score = c(0.1, 0.2, 0.5, 0.6, 0.8, 0.85, 0.86, 0.9, 0.99)
  )
  expect_message(
    {
      dfFlagged_Rate <- Flag_NormalApprox(
        dfAnalyzed_Rate,
        vFlag = c(2, 1, 0),
        vThreshold = c(0.85, 0.9)
      )
    },
    "Mismatch in vFlagOrder and vFlag values"
  )
  expect_equal(dfFlagged_Rate$Flag, c(2, 2, 2, 2, 2, 1, 1, 0, 0))

  expect_message(
    {
      dfFlagged_Rate <- Flag_NormalApprox(
        dfAnalyzed_Rate,
        vFlag = c(2, 1, 0),
        vThreshold = c(0.85, 0.9),
        vFlagOrder = c(0, 1, 2)
      )
    },
    "Sorted dfFlagged using custom Flag order"
  )
  expect_equal(dfFlagged_Rate$Flag, c(0, 0, 1, 1, 2, 2, 2, 2, 2))
})

test_that("Flag function works correctly with poisson data", {
  # Test with Poisson Data
  dfAnalyzedCustom <- dplyr::tribble(
    ~GroupID, ~Numerator, ~Denominator, ~Metric, ~Score, ~PredictedCount,
    "166", 5L, 857L, 0.0058343057176196, -11, 5.12722560489132,
    "76", 2L, 13L, 0.153846153846154, -6, 2.00753825876477,
    "86", 5L, 678L, 0.00737463126843658, 6, 4.86523613634436,
    "80", 5L, 678L, 0.00737463126843658, 11, 4.86523613634436
  )

  expect_message(
    {
      dfFlagged <- Flag_Poisson(dfAnalyzedCustom, vThreshold = c(-10, -5, 5, 10))
    },
    "Sorted dfFlagged using custom Flag order"
  )
  expect_equal(dfFlagged$Flag, c(2, -2, 1, -1))
  expect_equal(dfFlagged$GroupID, c("80", "166", "86", "76"))
})


test_that("Flag function works correctly with NA data", {
  dfAnalyzed_NA <- data.frame(
    GroupID = 1:7,
    Score = c(-4, -1, 0, NA, 2, 5, NA)
  )
  dfFlagged_NA <- Flag(dfAnalyzed_NA, vFlagOrder = NULL)
  expect_equal(dfFlagged_NA$Flag, c(-2, 0, 0, NA, 1, 2, NA))
})

test_that("Flag function adds RiskScoreWeight info to Analysis_Flagged (#77)", {
  dfAnalyzed <- data.frame(
    GroupID = 1:10,
    Score = c(-4, -2.5, -1.5, -0.5, 0.5, 1.5, 2.5, 3.5, NA, 0)
  )

  # Test with RiskScoreWeight parameter
  vRiskScoreWeight <- c(10, 5, 1, 3, 8)
  vFlag <- c(-2, -1, 0, 1, 2)

  dfFlagged <- Flag(
    dfAnalyzed,
    vThreshold = c(-3, -2, 2, 3),
    vFlag = vFlag,
    vRiskScoreWeight = vRiskScoreWeight,
    vFlagOrder = NULL
  )

  # Verify Weight and WeightMax columns are added
  expect_true("Weight" %in% names(dfFlagged))
  expect_true("WeightMax" %in% names(dfFlagged))

  # Verify WeightMax is correctly set to the maximum weight value
  expect_true(all(dfFlagged$WeightMax == max(vRiskScoreWeight), na.rm = TRUE))

  # Verify weights are correctly mapped to flag values
  expected_weights <- c(
    10, # Flag -2, Weight 10
    5, # Flag -1, Weight 5
    1, # Flag 0, Weight 1
    1, # Flag 0, Weight 1
    1, # Flag 0, Weight 1
    1, # Flag 0, Weight 1
    3, # Flag 1, Weight 3
    8, # Flag 2, Weight 8
    NA, # NA Flag gets NA Weight
    1 # Flag 0, Weight 1
  )
  expect_equal(dfFlagged$Weight, expected_weights)

  # Verify flag values are correct (basic sanity check)
  expected_flags <- c(-2, -1, 0, 0, 0, 0, 1, 2, NA, 0)
  expect_equal(dfFlagged$Flag, expected_flags)
})

test_that("errors working as expected (#135)", {
  dfAnalyzed <- data.frame(
    GroupID = 1:12,
    Score = c(-4, -3.1, -3, -2.9, -2.1, -2, -1.9, 0, 2, 2.9, 3, 3.1)
  )
  # Test with missing strColumn
  expect_error(Flag(dfAnalyzed, strColumn = "MissingColumn"), "strColumn not found in dfAnalyzed")

  # Test with improper number of flag values
  expect_error(Flag(dfAnalyzed, vThreshold = c(-2, 0, 2), vFlag = c(1, 2, 3)), "Improper number of Flag values provided")

  # Test with non-numeric vThreshold
  expect_error(Flag(dfAnalyzed, vThreshold = c("a", "b", "c")), "vThreshold is not numeric")

  # Test with non-character strColumn
  expect_error(Flag(dfAnalyzed, strColumn = 123), "strColumn is not character")

  # Test with non-data frame dfAnalyzed
  expect_error(Flag(list(SiteID = 1:10, Score = c(-4, -3, -2.5, -2, -1, 0, 1, 2, 2.5, 3))), "dfAnalyzed is not a data frame")

  # Test error when vFlag and vRiskScoreWeight have different lengths
  expect_error(
    Flag(dfAnalyzed, vRiskScoreWeight = c(1, 2, 3)),
    "vFlag and vRiskScoreWeight must be the same length"
  )
})

test_that("Flag correctly handles exact cut point values (include.lowest = TRUE) (#135)", {
  # With right = FALSE, intervals are [lo, hi). A score exactly at a negative threshold
  # falls in the left-closed interval starting at that threshold, so it receives a negative
  # (non-zero) flag rather than NA. include.lowest = TRUE additionally ensures Inf maps to
  # the highest flag instead of NA.
  dfAnalyzed <- data.frame(
    GroupID = 1:6,
    Score = c(-Inf, -3, -2, 2, 3, Inf)
  )

  dfFlagged <- Flag(dfAnalyzed, vFlagOrder = NULL)

  # -Inf: left endpoint of [-Inf, -3) → flag -2 (most negative)
  # -3:   left endpoint of [-3, -2)   → flag -1 (negative, i.e. flagged, not NA)
  # -2:   left endpoint of [-2,  2)   → flag  0
  #  2:   left endpoint of [ 2,  3)   → flag  1
  #  3:   left endpoint of [ 3, Inf)  → flag  2
  # Inf:  include.lowest = TRUE closes [3, Inf] → flag  2 (not NA)
  expect_equal(dfFlagged$Flag, c(-2, -1, 0, 1, 2, 2))
})
