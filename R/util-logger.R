# Log level numeric mapping (higher = more severe)
.log_levels <- c(
  "DEBUG" = 1L,
  "INFO" = 2L,
  "WARN" = 3L,
  "ERROR" = 4L,
  "FATAL" = 5L
)

#' Set the logging threshold level
#'
#' Controls which log messages are displayed. Messages below the threshold are
#' suppressed. Can accept either a character log level (e.g. "DEBUG", "WARN")
#' or a log4r logger object (for backward compatibility).
#'
#' @param logger A character string (one of "DEBUG", "INFO", "WARN", "ERROR",
#'   "FATAL") or a log4r logger object.
#' @export
SetLogger <- function(logger) {
  if (is.character(logger) && length(logger) == 1L) {
    level <- toupper(logger)
  } else if (inherits(logger, "logger") && !is.null(logger$threshold)) {
    # Map numeric threshold from log4r logger object
    level_map <- c("DEBUG", "INFO", "WARN", "ERROR", "FATAL")
    idx <- match(logger$threshold, seq_along(level_map))
    level <- if (!is.na(idx)) level_map[idx] else "DEBUG"
    # Extract appender if present
    appender <- logger$appenders %||% logger$appender
    if (!is.null(appender)) {
      .le$appender <- if (is.list(appender)) appender[[1L]] else appender
    }
  } else if (inherits(logger, "logger")) {
    level <- "DEBUG"
    appender <- logger$appenders %||% logger$appender
    if (!is.null(appender)) {
      .le$appender <- if (is.list(appender)) appender[[1L]] else appender
    }
  } else {
    level <- toupper(as.character(logger)[[1L]])
  }

  if (!level %in% names(.log_levels)) {
    rlang::abort(
      paste0("`logger` must be a log level (one of: ",
             paste(names(.log_levels), collapse = ", "),
             ") or a log4r logger object.")
    )
  }
  .le$log_level <- level
  invisible(NULL)
}

#' Get the current logging threshold level
#' @return Character string of the current log level.
#' @export
GetLogLevel <- function() {
  .le$log_level %||% "DEBUG"
}

#' Get the current log appender function
#' @return A function used as the log appender. Defaults to [cli_fmt].
#' @export
GetLogAppender <- function() {
  .le$appender %||% cli_fmt
}
