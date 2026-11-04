.onLoad <- function(libname, pkgname) {
  # Set the log level to the default value if it isn't already set.
  SetLogger(GetLogLevel()) # nocov
  gsm_testdata_use_dir() # nocov
  gsm_testdata_use_tag() # nocov
  gsm_testdata_use_channel() # nocov
  .register_testdata(asNamespace(pkgname)) # nocov
}
