# Test data for the whole run: a temporary cache and state, removed afterwards,
# so tests never touch the user's real gsm cache.
output_dir <- withr::local_tempdir(.local_envir = teardown_env())
withr::local_envvar(
  R_USER_CACHE_DIR = file.path(output_dir, "user-cache"),
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
