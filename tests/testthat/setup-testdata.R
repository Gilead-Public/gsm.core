# Find a local build (#219) in the user's real cache that matches the installed
# packages, before the cache is redirected below. Checked unconditionally, since
# the gsm.testdata_builder option isn't reliably passed to test processes.
local_build <- .testdata_local_match()

# Test data for the whole run: a temporary cache and state, removed afterwards,
# so tests never touch the user's real gsm cache.
output_dir <- withr::local_tempdir(.local_envir = teardown_env())
withr::local_envvar(
  R_USER_CACHE_DIR = file.path(output_dir, "user-cache"),
  .local_envir = teardown_env()
)
# Never build real test data in tests, even if the user's session (or
# .Rprofile) sets a builder. Tests that need one set a fake builder.
withr::local_options(
  gsm.testdata_builder = NULL,
  .local_envir = teardown_env()
)
# Restore the handle's own cache object, not a fresh default: a default made
# during teardown would point into the temporary R_USER_CACHE_DIR.
old_handle_cache <- gsm_testdata()$cache
old_testdata_cache <- use_testdata_cache_dir(file.path(output_dir, "testdata"))
withr::defer(
  {
    options(gsm.testdata_cache = old_testdata_cache)
    gsm_testdata()$set_cache(old_handle_cache)
  },
  envir = teardown_env()
)

# Serve the local build as a snapshot folder for the run, unless a folder or
# tag is already set explicitly.
if (
  !is.null(local_build) &&
    !nzchar(gsm$testdata_dir %||% "") &&
    !nzchar(gsm$testdata_tag %||% "")
) {
  old_snapshot <- use_testdata_snapshot(local_build)
  withr::defer(use_testdata_snapshot(old_snapshot), envir = teardown_env())
}
