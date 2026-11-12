.onLoad <- function(libname, pkgname) {
  # Set the log level to the default value if it isn't already set.
  SetLogger(GetLogLevel()) # nocov
  use_testdata_snapshot() # nocov
  use_testdata_tag() # nocov
  .register_testdata(asNamespace(pkgname)) # nocov
}
