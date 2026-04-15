TestAtLogLevel <- function(chrLevel = "ERROR", envir = rlang::caller_env()) {
  ConsoleAppender <- log4r::console_appender(layout = gsm.core::cli_fmt)
  withr::defer(
    gsm.core::SetLogger(log4r::logger(
      "DEBUG",
      appenders = ConsoleAppender
    )),
    envir = envir
  )
  gsm.core::SetLogger(log4r::logger(
    threshold = toupper(chrLevel),
    appenders = ConsoleAppender
  ))
}
