#' cli-style console appender for gsm
#'
#' Dispatches a log message to the appropriate `cli` function based on `level`.
#' Used as the default log appender.
#'
#' @inheritParams LogMessage
#' @returns `NULL`, invisibly.
#' @export
cli_fmt <- function(level, message, cli_detail = NULL) {
  switch(level,
    INFO = cli_fmt_inform(message, cli_detail),
    WARN = cli::cli_warn(message),
    ERROR = ,
    FATAL = cli::cli_abort(message)
  )
  return(NULL)
}

#' INFO-level cli dispatcher
#'
#' Routes an INFO-level message to the appropriate `cli` formatting function
#' based on `cli_detail`. Called internally by [cli_fmt()].
#'
#' @inheritParams LogMessage
#' @returns The return value of the dispatched `cli` function, invisibly.
#' @keywords internal
cli_fmt_inform <- function(message, cli_detail) {
  switch(cli_detail,
    h1            = cli::cli_h1(message),
    h2            = cli::cli_h2(message),
    h3            = cli::cli_h3(message),
    alert         = cli::cli_alert(message),
    alert_success = cli::cli_alert_success(message),
    alert_info    = cli::cli_alert_info(message),
    text          = cli::cli_text(message),
    inform        = cli::cli_inform(message)
  )
}

#' Log a message via the active appender
#'
#' Emits a log message at the specified level, provided the level meets or
#' exceeds the current log threshold. The message is glue-interpolated before
#' being passed to the active appender.
#'
#' @param level Log level: `"INFO"`, `"WARN"`, `"ERROR"`, or `"FATAL"`.
#'   Case-insensitive.
#' @param message Character string to display; may contain glue-style
#'   placeholders that are evaluated in `.envir`.
#' @param cli_detail For `level = "INFO"`, the cli style to use. Passed
#'   through to the active appender.
#' @param .envir Environment in which to evaluate glue expressions. Defaults
#'   to the caller's environment.
#'
#' @returns `NULL`, invisibly.
#' @export
LogMessage <- function(level, message, cli_detail = NULL, .envir = parent.frame()) {
  level <- toupper(level)

  # Check threshold
  if (.log_levels[[level]] < .log_levels[[GetLogLevel()]]) {
    return(invisible(NULL))
  }

  # Glue-interpolate if needed
  if (!inherits(message, "glue")) {
    message <- glue::glue(message, .envir = .envir)
  }

  appender <- GetLogAppender()
  appender(level = level, message = message, cli_detail = cli_detail)
  invisible(NULL)
}

#' Stop execution if a condition is true
#'
#' A thin wrapper around [LogMessage()] that emits an `"ERROR"`-level message
#' (triggering `cli::cli_abort()`) when `cnd` is `TRUE`.
#'
#' @param cnd Logical scalar. When `TRUE`, an error is raised.
#' @param message Character string to display; may contain glue-style
#'   placeholders.
#'
#' @returns `NULL`, invisibly, if `cnd` is `FALSE`. Does not return if `cnd`
#'   is `TRUE`.
#' @export
stop_if <- function(cnd, message) {
  if (cnd) {
    LogMessage(level = "error", message = message)
  }
}
