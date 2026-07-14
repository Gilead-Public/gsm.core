TestAtLogLevel <- function(chrLevel = "ERROR", envir = rlang::caller_env()) {
  old_level <- gsm.core::GetLogLevel()
  withr::defer(gsm.core::SetLogger(old_level), envir = envir)
  gsm.core::SetLogger(toupper(chrLevel))
}
