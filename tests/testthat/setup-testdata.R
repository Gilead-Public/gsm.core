# Test data for the whole run: a temporary cache and state, removed afterwards,
# so tests never touch the user's real gsm cache.
output_dir <- withr::local_tempdir(.local_envir = teardown_env())
withr::local_envvar(
  R_USER_CACHE_DIR = file.path(output_dir, "user-cache"),
  .local_envir = teardown_env()
)
old_testdata_cache <- use_testdata_cache_dir(file.path(output_dir, "testdata"))
withr::defer(
  use_testdata_cache_dir(old_testdata_cache),
  envir = teardown_env()
)
