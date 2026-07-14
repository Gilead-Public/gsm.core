test_that("SetLogger accepts a character level", {
  old <- GetLogLevel()
  withr::defer(SetLogger(old))

  SetLogger("WARN")
  expect_equal(GetLogLevel(), "WARN")

  # case-insensitive

  SetLogger("debug")
  expect_equal(GetLogLevel(), "DEBUG")
})

test_that("SetLogger accepts a log4r logger object with threshold", {
  old <- GetLogLevel()
  withr::defer(SetLogger(old))

  fake_logger <- structure(list(threshold = 3L), class = "logger")
  SetLogger(fake_logger)
  expect_equal(GetLogLevel(), "WARN")

  # Unrecognized numeric threshold falls back to DEBUG
  fake_logger2 <- structure(list(threshold = 99L), class = "logger")
  SetLogger(fake_logger2)
  expect_equal(GetLogLevel(), "DEBUG")
})

test_that("SetLogger accepts a log4r logger object without threshold", {
  old <- GetLogLevel()
  withr::defer(SetLogger(old))

  fake_logger <- structure(list(), class = "logger")
  SetLogger(fake_logger)
  expect_equal(GetLogLevel(), "DEBUG")
})

test_that("SetLogger falls back to as.character for other inputs", {
  old <- GetLogLevel()
  withr::defer(SetLogger(old))

  SetLogger(factor("INFO"))
  expect_equal(GetLogLevel(), "INFO")
})

test_that("SetLogger errors on invalid level", {
  expect_error(SetLogger("BANANA"), "must be a log level")
})

test_that("GetLogLevel returns DEBUG when unset", {
  old <- .le$log_level
  withr::defer(.le$log_level <- old)

  .le$log_level <- NULL
  expect_equal(GetLogLevel(), "DEBUG")
})
