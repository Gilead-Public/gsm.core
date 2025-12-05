# test-util-cli_logger_wrappers.R
test_that("Use cli style messages via logger", {
  # Condense empty lines to stabilize snapshots between testthat versions.
  cleaner <- function(txt) {
    txt <- gsub("(^\\s+)|(\\s+$)", "", txt)
    txt[nzchar(txt)]
  }

  expect_snapshot(
    {
      LogMessage(
        level = "info",
        message = "cli style info",
        cli_detail = "h1"
      )
    },
    transform = cleaner
  )
  expect_snapshot(
    {
      LogMessage(
        level = "info",
        message = "cli style info",
        cli_detail = "h2"
      )
    },
    transform = cleaner
  )
  expect_snapshot(
    {
      LogMessage(
        level = "info",
        message = "cli style info",
        cli_detail = "h3"
      )
    },
    transform = cleaner
  )
  expect_snapshot(
    {
      LogMessage(
        level = "info",
        message = "cli style info",
        cli_detail = "alert_success"
      )
    },
    transform = cleaner
  )
  expect_snapshot(
    {
      tryCatch(LogMessage(
        level = "warn",
        message = "cli style warn"
      ))
    },
    transform = cleaner
  )
  expect_error({
    LogMessage(level = "error", message = "cli style error")
  })
})
