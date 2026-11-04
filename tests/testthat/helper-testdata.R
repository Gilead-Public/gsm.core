# Helpers for test-testdata.R. The fake release server and pkg_state() /
# manifest_versions() live in helper-refresh.R.

# Isolate cache, env vars, manifest memo, and network for one test.
local_testdata_env <- function(server, installed, env = parent.frame()) {
  cache <- withr::local_tempdir(.local_envir = env)
  local_testdata_settings(env = env)
  withr::local_options(gsm.testdata_cache = NULL, .local_envir = env)
  testthat::local_mocked_bindings(
    .testdata_dir = function() cache,
    .fresh_default_request = server$request,
    .testdata_candidates = function(state) names(installed()),
    .testdata_installed = function(pkgs) installed(),
    .env = env
  )
  rm(list = ls(.testdata_manifests), envir = .testdata_manifests)
  withr::defer(
    rm(list = ls(.testdata_manifests), envir = .testdata_manifests),
    envir = env
  )
  invisible(cache)
}

# Clear gsm.core's test data settings and handle for one test, restoring them
# afterwards. Optional arguments set values for the test.
local_testdata_settings <- function(dir = NULL, tag = NULL, channel = NULL,
                                    env = parent.frame()) {
  names <- c("testdata_dir", "testdata_tag", "testdata_channel",
             "testdata_handle")
  old <- mget(names, envir = gsm, ifnotfound = list(NULL))
  withr::defer(
    for (n in names) assign(n, old[[n]], envir = gsm),
    envir = env
  )
  for (n in names) assign(n, NULL, envir = gsm)
  gsm_testdata_use_dir(dir)
  gsm_testdata_use_tag(tag)
  gsm_testdata_use_channel(channel)
  invisible()
}

# Run the gsm checker against the state file in a test cache dir.
run_checker <- function(cache) {
  .testdata_checker(state_file(file.path(cache, "testdata-state.rds")))
}

# Point gsm_testdata_use_dir() at a published fake bundle.
local_bundle_dir <- function(server, tag) {
  dir <- file.path(server$root, tag)
  gsm_testdata_use_dir(dir)
  dir
}
