.onLoad <- function(libname, pkgname) {
  # Only set the log level if it isn't already set.
  if (is.null(.le$log_level)) {
    SetLogger("DEBUG") # nocov
  }
}
