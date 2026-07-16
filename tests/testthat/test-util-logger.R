test_that("SetLogger accepts a character level (#159)", {
  old <- GetLogLevel()
  withr::defer(SetLogger(old))

  SetLogger("WARN")
  expect_equal(GetLogLevel(), "WARN")

  # case-insensitive

  SetLogger("debug")
  expect_equal(GetLogLevel(), "DEBUG")
})

test_that("SetLogger accepts a log4r logger object with threshold (#159)", {
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

test_that("SetLogger accepts a log4r logger object without threshold (#159)", {
  old <- GetLogLevel()
  withr::defer(SetLogger(old))

  fake_logger <- structure(list(), class = "logger")
  SetLogger(fake_logger)
  expect_equal(GetLogLevel(), "DEBUG")
})

test_that("SetLogger falls back to as.character for other inputs (#159)", {
  old <- GetLogLevel()
  withr::defer(SetLogger(old))

  SetLogger(factor("INFO"))
  expect_equal(GetLogLevel(), "INFO")
})

test_that("SetLogger errors on invalid level (#159)", {
  expect_error(SetLogger("BANANA"), "DEBUG")
})

test_that("SetLogLevel errors on invalid character level (#159)", {
  expect_error(SetLogLevel("BANANA"), "DEBUG")
})

test_that("SetLogLevel.default errors on unsupported non-empty type (#159)", {
  expect_error(SetLogLevel(list("INFO")), "character or numeric")
})

test_that("SetLogLevel sets the log level directly (#159)", {
  old <- GetLogLevel()
  withr::defer(SetLogLevel(old))

  SetLogLevel("ERROR")
  expect_equal(GetLogLevel(), "ERROR")

  # case-insensitive
  SetLogLevel("warn")
  expect_equal(GetLogLevel(), "WARN")
})

test_that("SetLogLevel accepts a numeric level (#159)", {
  old <- GetLogLevel()
  withr::defer(SetLogLevel(old))

  SetLogLevel(3L)
  expect_equal(GetLogLevel(), "WARN")

  # Unrecognized numeric falls back to DEBUG
  SetLogLevel(99L)
  expect_equal(GetLogLevel(), "DEBUG")
})

test_that("SetLogLevel defaults to DEBUG for NULL (via .default) (#159)", {
  old <- GetLogLevel()
  withr::defer(SetLogLevel(old))

  SetLogLevel(NULL)
  expect_equal(GetLogLevel(), "DEBUG")
})

test_that("SetLogLevel defaults to DEBUG for character() (via .character) (#159)", {
  old <- GetLogLevel()
  withr::defer(SetLogLevel(old))

  SetLogLevel(character())
  expect_equal(GetLogLevel(), "DEBUG")
})

test_that("SetLogAppender sets and GetLogAppender retrieves an appender (#159)", {
  old_appender <- .le$appender
  withr::defer(.le$appender <- old_appender)

  my_appender <- function(level, ...) NULL
  SetLogAppender(my_appender)
  expect_identical(GetLogAppender(), my_appender)
})

test_that("SetLogAppender defaults to cli_fmt (#159)", {
  old_appender <- .le$appender
  withr::defer(.le$appender <- old_appender)

  SetLogAppender()
  expect_identical(GetLogAppender(), cli_fmt)
})

test_that("GetLogLevel returns DEBUG when unset (#159)", {
  old <- .le$log_level
  withr::defer(.le$log_level <- old)

  .le$log_level <- NULL
  expect_equal(GetLogLevel(), "DEBUG")
})

test_that("GetLogAppender returns cli_fmt by default (#159)", {
  old <- .le$appender
  withr::defer(.le$appender <- old)

  .le$appender <- NULL
  expect_identical(GetLogAppender(), cli_fmt)
})

test_that("SetLogger extracts appender from log4r logger with appenders list (#159)", {
  old_level <- GetLogLevel()
  old_appender <- .le$appender
  withr::defer({
    SetLogger(old_level)
    .le$appender <- old_appender
  })

  my_appender <- function(level, ...) NULL
  fake_logger <- structure(
    list(threshold = 2L, appenders = list(my_appender)),
    class = "logger"
  )
  SetLogger(fake_logger)
  expect_equal(GetLogLevel(), "INFO")
  expect_identical(GetLogAppender(), my_appender)
})

test_that("SetLogger extracts single appender from log4r logger (#159)", {
  old_level <- GetLogLevel()
  old_appender <- .le$appender
  withr::defer({
    SetLogger(old_level)
    .le$appender <- old_appender
  })

  my_appender <- function(level, ...) NULL
  fake_logger <- structure(
    list(threshold = 4L, appender = my_appender),
    class = "logger"
  )
  SetLogger(fake_logger)
  expect_equal(GetLogLevel(), "ERROR")
  expect_identical(GetLogAppender(), my_appender)
})

test_that("SetLogger extracts appender from logger without threshold (#159)", {
  old_level <- GetLogLevel()
  old_appender <- .le$appender
  withr::defer({
    SetLogger(old_level)
    .le$appender <- old_appender
  })

  my_appender <- function(level, ...) NULL
  fake_logger <- structure(list(appenders = list(my_appender)), class = "logger")
  SetLogger(fake_logger)
  expect_equal(GetLogLevel(), "DEBUG")
  expect_identical(GetLogAppender(), my_appender)
})

test_that("LogMessage uses custom appender (#159)", {
  old_level <- GetLogLevel()
  old_appender <- .le$appender
  withr::defer({
    SetLogger(old_level)
    .le$appender <- old_appender
  })

  captured <- list()
  my_appender <- function(level, ...) {
    captured[[length(captured) + 1L]] <<- list(level = level, ...)
  }
  .le$appender <- my_appender
  SetLogger("DEBUG")

  LogMessage("INFO", "hello", cli_detail = "alert")
  expect_equal(captured[[1]]$level, "INFO")
  expect_equal(captured[[1]]$message, "hello")
})
