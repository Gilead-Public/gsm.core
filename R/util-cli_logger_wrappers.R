#' cli style console appender for gsm
#'
#' @param level warning level
#' @param ... should contain message and cli_detail
#'
#' @export
cli_fmt <- function(level, ...) {
  fields <- list(...)
  if (level == "INFO" && fields$cli_detail == "h1") {
    cli::cli_h1(fields$message)
  } else if (level == "INFO" && fields$cli_detail == "h2") {
    cli::cli_h2(fields$message)
  } else if (level == "INFO" && fields$cli_detail == "h3") {
    cli::cli_h3(fields$message)
  } else if (level == "INFO" && fields$cli_detail == "alert") {
    cli::cli_alert(fields$message)
  } else if (level == "INFO" && fields$cli_detail == "alert_success") {
    cli::cli_alert_success(fields$message)
  } else if (level == "INFO" && fields$cli_detail == "alert_info") {
    cli::cli_alert_info(fields$message)
  } else if (level == "INFO" && fields$cli_detail == "text") {
    cli::cli_text(fields$message)
  } else if (level == "INFO" && fields$cli_detail == "inform") {
    cli::cli_inform(fields$message)
  } else if (level == "WARN") {
    cli::cli_warn(fields$message)
  } else if (level == "ERROR") {
    cli::cli_abort(fields$message)
  } else if (level == "FATAL") {
    cli::cli_abort(fields$message)
  }
  return(NULL)
}

#' Custom logging function that wraps cli messaging
#' @param level logger levels
#' @param message message to display; may contain glue-style placeholders
#' @param cli_detail for cli style alerts the detail for info
#' @param .envir the environment for glue expressions
#'
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

  cli_fmt(level = level, message = message, cli_detail = cli_detail)
  invisible(NULL)
}

#' Custom stop message
#' @param cnd condition for stopping
#' @param message message to display; may contain glue-style placeholders
#'
#' @export
stop_if <- function(cnd, message) {
  if (cnd) {
    LogMessage(level = "error", message = message)
  }
}
