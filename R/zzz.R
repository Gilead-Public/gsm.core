.onLoad <- function(libname, pkgname) {
  # Set the log level to the default value if it isn't already set.
  SetLogger(GetLogLevel()) # nocov
}
