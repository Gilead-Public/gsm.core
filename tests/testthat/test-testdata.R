test_that(".testdata_channel() infers dev/prod and honours the override (#206)", {
  local_testdata_settings()
  expect_equal(.testdata_channel(pkg_state(gsm.core = "2.1.0")), "prod")
  expect_equal(
    .testdata_channel(pkg_state(gsm.core = "2.1.0", gsm.kri = "1.7.0.9001")),
    "dev"
  )
  expect_equal(
    .testdata_channel(pkg_state(gsm.core = "2.1.0", gsm.x = NA_character_)),
    "prod"
  )
  gsm_testdata_use_channel("exp1")
  expect_equal(.testdata_channel(pkg_state(gsm.core = "2.1.0.9000")), "exp1")
  expect_equal(.testdata_channel(pkg_state(gsm.core = "2.1.0.9000")), "exp1")
  gsm_testdata_use_channel("")
  expect_equal(.testdata_channel(pkg_state(gsm.core = "2.1.0")), "prod")
  gsm_testdata_use_channel("Bad-Name")
  expect_error(.testdata_channel(pkg_state(gsm.core = "2.1.0")), "must match")
})

test_that(".testdata_is_outdated() compares versions, then SHAs (#206)", {
  manifest <- list(
    package_versions = manifest_versions(
      gsm.core = c("2.1.0", "aaa"),
      gsm.kri = "1.7.0"
    )
  )
  expect_false(.testdata_is_outdated(
    pkg_state(gsm.core = c("2.1.0", "aaa")),
    manifest
  ))
  expect_false(.testdata_is_outdated(pkg_state(gsm.core = "2.0.0"), manifest))
  expect_true(.testdata_is_outdated(
    pkg_state(gsm.core = "2.1.0.9000"),
    manifest
  ))
  expect_true(.testdata_is_outdated(
    pkg_state(gsm.core = c("2.1.0", "bbb")),
    manifest
  ))
  # No SHA on either side: version match is enough.
  expect_false(.testdata_is_outdated(pkg_state(gsm.core = "2.1.0"), manifest))
  expect_false(.testdata_is_outdated(
    pkg_state(gsm.kri = c("1.7.0", "zzz")),
    manifest
  ))
  # Not installed, or not in the manifest: ignored.
  expect_false(.testdata_is_outdated(
    pkg_state(gsm.core = NA_character_),
    manifest
  ))
  expect_false(.testdata_is_outdated(pkg_state(gsm.new = "9.9.9"), manifest))
})

test_that("cold cache resolves the pointer for the inferred channel (#206)", {
  server <- local_fake_releases()
  server$publish(
    "testdata-prod-1",
    package_versions = manifest_versions(gsm.core = "2.1.0"),
    pointer_channel = "prod"
  )
  installed <- pkg_state(gsm.core = "2.1.0")
  cache <- local_testdata_env(server, function() installed)

  expect_equal(run_checker(cache), "testdata-prod-1")
  expect_true(any(grepl("testdata-prod-latest", server$requests())))
})

test_that("unchanged installed packages make no network calls (#206)", {
  server <- local_fake_releases()
  server$publish(
    "testdata-prod-1",
    package_versions = manifest_versions(gsm.core = "2.1.0"),
    pointer_channel = "prod"
  )
  installed <- pkg_state(gsm.core = "2.1.0")
  cache <- local_testdata_env(server, function() installed)
  run_checker(cache)

  server$reset_requests()
  rm(list = ls(.testdata_manifests), envir = .testdata_manifests)
  expect_equal(run_checker(cache), "testdata-prod-1")
  expect_length(server$requests(), 0)
})

test_that("changed but not newer packages keep the tag without the pointer (#206)", {
  server <- local_fake_releases()
  server$publish(
    "testdata-prod-1",
    package_versions = manifest_versions(gsm.core = "2.1.0"),
    pointer_channel = "prod"
  )
  installed <- pkg_state(gsm.core = "2.1.0")
  cache <- local_testdata_env(server, function() installed)
  run_checker(cache)

  installed <- pkg_state(gsm.core = "2.0.0")
  server$reset_requests()
  expect_equal(run_checker(cache), "testdata-prod-1")
  expect_false(any(grepl("-latest", server$requests())))
})

test_that("a newer installed package switches to the new pointer tag (#206)", {
  server <- local_fake_releases()
  server$publish(
    "testdata-prod-1",
    package_versions = manifest_versions(gsm.core = "2.1.0"),
    pointer_channel = "prod"
  )
  installed <- pkg_state(gsm.core = "2.1.0")
  cache <- local_testdata_env(server, function() installed)
  run_checker(cache)

  server$publish(
    "testdata-prod-2",
    package_versions = manifest_versions(gsm.core = "2.2.0"),
    pointer_channel = "prod"
  )
  installed <- pkg_state(gsm.core = "2.2.0")
  expect_equal(run_checker(cache), "testdata-prod-2")

  # And the next session takes the fast path.
  server$reset_requests()
  expect_equal(run_checker(cache), "testdata-prod-2")
  expect_length(server$requests(), 0)
})

test_that("same version with a different RemoteSha triggers a pointer check (#206)", {
  server <- local_fake_releases()
  server$publish(
    "testdata-prod-1",
    package_versions = manifest_versions(gsm.core = c("2.1.0", "aaa")),
    pointer_channel = "prod"
  )
  installed <- pkg_state(gsm.core = c("2.1.0", "aaa"))
  cache <- local_testdata_env(server, function() installed)
  run_checker(cache)

  installed <- pkg_state(gsm.core = c("2.1.0", "bbb"))
  server$reset_requests()
  expect_message(run_checker(cache), "newer than the latest")
  expect_true(any(grepl("testdata-prod-latest", server$requests())))
})

test_that("installed packages newer than the latest bundle produce a message (#206)", {
  server <- local_fake_releases()
  server$publish(
    "testdata-dev-1",
    package_versions = manifest_versions(gsm.core = "2.1.0"),
    pointer_channel = "dev"
  )
  installed <- pkg_state(gsm.core = "2.1.0.9001")
  cache <- local_testdata_env(server, function() installed)
  expect_message(
    expect_equal(run_checker(cache), "testdata-dev-1"),
    "newer than the latest"
  )
})

test_that("channels are cached independently (#206)", {
  server <- local_fake_releases()
  server$publish("testdata-prod-1", pointer_channel = "prod")
  server$publish("testdata-dev-1", pointer_channel = "dev")
  installed <- pkg_state(gsm.core = "2.1.0")
  cache <- local_testdata_env(server, function() installed)

  expect_equal(run_checker(cache), "testdata-prod-1")
  installed <- pkg_state(gsm.core = "2.1.0.9000")
  expect_equal(run_checker(cache), "testdata-dev-1")
  gsm_testdata_use_channel("prod")
  server$reset_requests()
  expect_equal(run_checker(cache), "testdata-prod-1")
})

test_that("gsm_testdata_use_tag() pins a tag and skips the pointer (#206)", {
  server <- local_fake_releases()
  server$publish("testdata-prod-1", pointer_channel = "prod")
  server$publish("testdata-old")
  installed <- pkg_state(gsm.core = "2.1.0")
  cache <- local_testdata_env(server, function() installed)
  gsm_testdata_use_tag("testdata-old")

  expect_equal(run_checker(cache), "testdata-old")
  expect_false(any(grepl("-latest", server$requests())))
})

test_that("a missing channel release gives a clear error (#206)", {
  server <- local_fake_releases()
  installed <- pkg_state(gsm.core = "2.1.0")
  cache <- local_testdata_env(server, function() installed)
  expect_error(run_checker(cache), "No \"prod\" test data release")
})

test_that("bindings download, verify, and cache assets end to end (#206)", {
  server <- local_fake_releases()
  server$publish(
    "testdata-prod-1",
    assets = list(a.rds = mtcars, b.rds = list(x = 1)),
    package_versions = manifest_versions(gsm.core = "2.1.0"),
    pointer_channel = "prod"
  )
  installed <- pkg_state(gsm.core = "2.1.0")
  cache <- local_testdata_env(server, function() installed)
  local_mocked_bindings(.testdata_assets = c(dfA = "a.rds", lstB = "b.rds"))

  env <- new.env()
  handle <- .register_testdata(env)
  expect_equal(env$dfA, mtcars)
  expect_equal(env$lstB$x, 1)
  expect_identical(gsm_testdata(), handle)
  expect_s3_class(handle$cache, "cache_disk")
  expect_length(handle$cache$keys(), 2)
  expect_true(file.exists(file.path(cache, "testdata-state.rds")))

  # Second load: served from disk, no asset downloads.
  server$reset_requests()
  env2 <- new.env()
  .register_testdata(env2)
  expect_equal(env2$dfA, mtcars)
  expect_false(any(grepl("a\\.rds$", server$requests())))
})

test_that("a corrupted asset fails the checksum (#206)", {
  server <- local_fake_releases()
  server$publish(
    "testdata-prod-1",
    assets = list(a.rds = mtcars),
    pointer_channel = "prod"
  )
  saveRDS(iris, file.path(server$root, "testdata-prod-1", "a.rds"))
  installed <- pkg_state(gsm.core = "2.1.0")
  local_testdata_env(server, function() installed)
  local_mocked_bindings(.testdata_assets = c(dfA = "a.rds"))

  env <- new.env()
  .register_testdata(env)
  expect_error(env$dfA, "Checksum mismatch")
})

test_that("the gsm.testdata_cache option supplies the user's cache (#206)", {
  server <- local_fake_releases()
  server$publish(
    "testdata-prod-1",
    assets = list(a.rds = mtcars),
    pointer_channel = "prod"
  )
  installed <- pkg_state(gsm.core = "2.1.0")
  local_testdata_env(server, function() installed)
  local_mocked_bindings(.testdata_assets = c(dfA = "a.rds"))
  mine <- cachem::cache_mem()
  withr::local_options(gsm.testdata_cache = mine)

  env <- new.env()
  handle <- .register_testdata(env)
  env$dfA
  expect_identical(handle$cache, mine)
  expect_length(mine$keys(), 1)
})

test_that("gsm_testdata(cache = ) swaps the cache and sets the option (#206)", {
  server <- local_fake_releases()
  server$publish(
    "testdata-prod-1",
    assets = list(a.rds = mtcars),
    pointer_channel = "prod"
  )
  installed <- pkg_state(gsm.core = "2.1.0")
  local_testdata_env(server, function() installed)
  local_mocked_bindings(.testdata_assets = c(dfA = "a.rds"))
  withr::local_options(gsm.testdata_cache = NULL)

  env <- new.env()
  handle <- .register_testdata(env)
  expect_s3_class(handle$cache, "cache_disk")

  # NULL (option unset) keeps the current cache.
  expect_identical(gsm_testdata()$cache, handle$cache)

  mine <- cachem::cache_mem()
  gsm_testdata(cache = mine)
  expect_identical(handle$cache, mine)
  expect_identical(getOption("gsm.testdata_cache"), mine)
  env$dfA
  expect_length(mine$keys(), 1)
})

test_that("gsm_testdata_use_dir() reads a local bundle with no network or cache (#206)", {
  server <- local_fake_releases()
  server$publish(
    "local-bundle",
    assets = list(a.rds = mtcars),
    package_versions = manifest_versions(gsm.core = "2.1.0")
  )
  installed <- pkg_state(gsm.core = "2.1.0")
  local_testdata_env(server, function() installed)
  local_mocked_bindings(.testdata_assets = c(dfA = "a.rds"))
  local_bundle_dir(server, "local-bundle")
  # Takes priority over the other overrides.
  gsm_testdata_use_tag("testdata-nope")

  env <- new.env()
  handle <- .register_testdata(env)
  expect_equal(env$dfA, mtcars)
  expect_length(server$requests(), 0)
  expect_length(handle$cache$keys(), 0)
  expect_s3_class(handle$key(), "fresh_uncached")
})

test_that("gsm_testdata_use_dir() uses a stale bundle with a message (#206)", {
  server <- local_fake_releases()
  server$publish(
    "local-bundle",
    assets = list(a.rds = mtcars),
    package_versions = manifest_versions(gsm.core = "2.1.0")
  )
  installed <- pkg_state(gsm.core = "2.2.0")
  local_testdata_env(server, function() installed)
  local_mocked_bindings(.testdata_assets = c(dfA = "a.rds"))
  local_bundle_dir(server, "local-bundle")

  env <- new.env()
  .register_testdata(env)
  expect_message(expect_equal(env$dfA, mtcars), "newer than the test data")
  expect_length(server$requests(), 0)
})

test_that("gsm_testdata_use_dir() verifies checksums (#206)", {
  server <- local_fake_releases()
  server$publish("local-bundle", assets = list(a.rds = mtcars))
  saveRDS(iris, file.path(server$root, "local-bundle", "a.rds"))
  installed <- pkg_state(gsm.core = "2.1.0")
  local_testdata_env(server, function() installed)
  local_mocked_bindings(.testdata_assets = c(dfA = "a.rds"))
  local_bundle_dir(server, "local-bundle")

  env <- new.env()
  .register_testdata(env)
  expect_error(env$dfA, "Checksum mismatch")
})

test_that("gsm_testdata_use_dir() errors clearly on bad folders (#206)", {
  server <- local_fake_releases()
  server$publish("local-bundle", assets = list(a.rds = mtcars))
  installed <- pkg_state(gsm.core = "2.1.0")
  local_testdata_env(server, function() installed)
  local_mocked_bindings(.testdata_assets = c(dfA = "a.rds", dfB = "b.rds"))

  env <- new.env()
  .register_testdata(env)
  local_bundle_dir(server, "local-bundle")
  expect_error(env$dfB, "b.rds.*not found")

  gsm_testdata_use_dir(file.path(server$root, "missing"))
  env2 <- new.env()
  .register_testdata(env2)
  expect_error(env2$dfA, "does not exist")

  empty <- withr::local_tempdir()
  gsm_testdata_use_dir(empty)
  env3 <- new.env()
  .register_testdata(env3)
  expect_error(env3$dfA, "No .*manifest.json")
})

test_that("setters return the old value and re-check on next access (#206)", {
  server <- local_fake_releases()
  server$publish(
    "testdata-prod-1",
    assets = list(a.rds = 1),
    pointer_channel = "prod"
  )
  server$publish(
    "testdata-exp-1",
    assets = list(a.rds = 2),
    pointer_channel = "exp"
  )
  installed <- pkg_state(gsm.core = "2.1.0")
  local_testdata_env(server, function() installed)
  local_mocked_bindings(.testdata_assets = c(x = "a.rds"))

  env <- new.env()
  .register_testdata(env)
  expect_equal(env$x, 1)
  expect_null(gsm_testdata_use_channel("exp"))
  expect_equal(env$x, 2)
  expect_equal(gsm_testdata_use_channel(NULL), "exp")
  expect_equal(env$x, 1)
  gsm_testdata_use_tag(c("a", "b"))
  expect_error(env$x, "single string")
})

test_that("setter defaults read environment variables (#206)", {
  local_testdata_settings()
  withr::local_envvar(
    GSM_TESTDATA_DIR = "some/dir",
    GSM_TESTDATA_TAG = NA,
    GSM_TESTDATA_CHANNEL = "Bad-Name"
  )
  # Setting never errors, so .onLoad is safe even with bad values.
  expect_no_error({
    gsm_testdata_use_dir()
    gsm_testdata_use_tag()
    gsm_testdata_use_channel()
  })
  expect_equal(gsm$testdata_dir, "some/dir")
  expect_null(.testdata_setting("testdata_tag"))
  expect_error(
    .testdata_setting("testdata_channel", "^[a-z0-9]+$"),
    "gsm_testdata_use_channel"
  )
})
