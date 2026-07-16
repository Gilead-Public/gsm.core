TestAtLogLevel <- function(chrLevel = "ERROR", envir = rlang::caller_env()) {
  old_level <- gsm.core::GetLogLevel()
  withr::defer(gsm.core::SetLogLevel(old_level), envir = envir)
  gsm.core::SetLogLevel(toupper(chrLevel))
}
