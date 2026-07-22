# Log level numeric mapping (higher = more severe)
.log_levels <- c(
  "DEBUG" = 1L,
  "INFO" = 2L,
  "WARN" = 3L,
  "ERROR" = 4L,
  "FATAL" = 5L
)

#' Set the active log level
#'
#' Validates `level` and sets `.le$log_level`. Called internally by
#' [SetLogger()] methods and may be called directly when only the level (not a
#' logger object) needs to change.
#'
#' @param level A character string (one of `"DEBUG"`, `"INFO"`, `"WARN"`,
#'   `"ERROR"`, `"FATAL"`; case-insensitive) or an integer corresponding to
#'   a log4r numeric threshold. Defaults to `"DEBUG"` when `level` has zero
#'   length (e.g. `NULL`).
#' @returns `NULL`, invisibly.
#' @export
SetLogLevel <- function(level) {
  UseMethod("SetLogLevel")
}

#' @rdname SetLogLevel
#' @export
SetLogLevel.character <- function(level) {
  if (!length(level)) {
    level <- "DEBUG"
  } else {
    level <- toupper(level[[1L]])
  }
  if (!level %in% names(.log_levels)) {
    cli::cli_abort(
      c(
        "`level` must be one of {names(.log_levels)}",
        x = "Got {.val {level}}"
      )
    )
  }
  .le$log_level <- level
  invisible(NULL)
}

#' @rdname SetLogLevel
#' @export
SetLogLevel.numeric <- function(level) {
  idx <- match(level[[1L]], .log_levels, nomatch = 1L)
  SetLogLevel.character(names(.log_levels)[[idx]])
}

#' @rdname SetLogLevel
#' @export
SetLogLevel.default <- function(level) {
  if (length(level)) {
    cli::cli_abort(
      c(
        "{.arg level} must be a character or numeric value.",
        x = "{.arg level} is {.obj_type_friendly {level}}."
      )
    )
  }
  SetLogLevel("DEBUG")
}

#' Set the logging threshold level
#'
#' Controls which log messages are displayed. Messages below the threshold are
#' suppressed. Accepts a character log level (e.g. `"DEBUG"`, `"WARN"`) or a
#' log4r logger object (for backward compatibility).
#'
#' @param logger A character string (one of `"DEBUG"`, `"INFO"`, `"WARN"`,
#'   `"ERROR"`, `"FATAL"`) or a log4r logger object.
#' @export
SetLogger <- function(logger) {
  UseMethod("SetLogger")
}

#' @rdname SetLogger
#' @export
SetLogger.character <- function(logger) {
  SetLogLevel(logger[[1L]])
}

#' @rdname SetLogger
#' @export
SetLogger.logger <- function(logger) {
  appender <- logger$appenders %||% logger$appender
  if (!is.null(appender)) {
    .le$appender <- if (is.list(appender)) appender[[1L]] else appender
  }
  SetLogLevel(logger$threshold %||% "DEBUG")
}

#' @rdname SetLogger
#' @export
SetLogger.default <- function(logger) {
  SetLogLevel(as.character(logger)[[1L]])
}

#' Get the current logging threshold level
#' @return Character string of the current log level.
#' @export
GetLogLevel <- function() {
  .le$log_level %||% "DEBUG"
}

#' Set the active log appender
#'
#' Sets the function used to emit log messages. The appender must accept
#' `level`, `message`, and `cli_detail` arguments (see [cli_fmt()]).
#'
#' @param appender A function to use as the log appender. Defaults to
#'   [cli_fmt].
#' @returns `NULL`, invisibly.
#' @export
SetLogAppender <- function(appender = cli_fmt) {
  .le$appender <- appender
  invisible(NULL)
}

#' Get the current log appender function
#' @return A function used as the log appender. Defaults to [cli_fmt].
#' @export
GetLogAppender <- function() {
  .le$appender %||% cli_fmt
}
