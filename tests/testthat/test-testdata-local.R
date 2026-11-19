# Local test data builds (#219).

test_that("option unset: behavior and errors are unchanged (#219)", {
  withr::local_options(gsm.testdata_builder = NULL)
  server <- local_published()
  cache <- local_testdata_env(server, function() {
    helper_pkg_state(gsm.core = "1.0.0", gsm.kri = "0.5.0")
  })
  expect_error(helper_run_checker(cache), class = "gsm_testdata_no_match")
  expect_error(helper_run_checker(cache), "gsm.testdata_builder")
  expect_false(dir.exists(file.path(cache, "local")))
})

test_that(".testdata_builder() resolves functions and strings (#219)", {
  withr::local_options(gsm.testdata_builder = NULL)
  expect_null(.testdata_builder())
  withr::local_options(gsm.testdata_builder = identity)
  expect_identical(.testdata_builder(), identity)
  withr::local_options(gsm.testdata_builder = "base::identity")
  expect_identical(.testdata_builder(), identity)
  withr::local_options(gsm.testdata_builder = "identity")
  expect_error(.testdata_builder(), "function or a")
  withr::local_options(gsm.testdata_builder = 1)
  expect_error(.testdata_builder(), "function or a")
  withr::local_options(gsm.testdata_builder = "notapkg123::fn")
  expect_error(.testdata_builder(), "Can't find the test data builder")
  withr::local_options(gsm.testdata_builder = "base::pi")
  expect_error(.testdata_builder(), "isn't a function")
})

test_that("an exact match never builds (#219)", {
  builder <- local_fake_builder()
  withr::local_options(gsm.testdata_builder = builder$fn)
  server <- local_published()
  cache <- local_testdata_env(server, function() {
    helper_pkg_state(gsm.core = c("1.0.0", "s1"), gsm.kri = c("1.0.0", "k1"))
  })
  expect_match(helper_run_checker(cache), "^data-")
  expect_equal(builder$calls(), 0)
})

test_that("fully published installs still use releases (#219)", {
  builder <- local_fake_builder()
  withr::local_options(gsm.testdata_builder = builder$fn)
  server <- local_published()
  cache <- local_testdata_env(server, function() {
    helper_pkg_state(gsm.core = c("1.0.0", "s1"), gsm.kri = c("1.0.0", "k9"))
  })
  helper_run_checker(cache)
  expect_equal(builder$calls(), 0)
})

test_that("a local package builds once, then reuses the build (#219)", {
  builder <- local_fake_builder(list(lSource = list(x = "local")))
  withr::local_options(gsm.testdata_builder = builder$fn)
  server <- local_published()
  installed <- helper_pkg_state(gsm.core = "1.0.0", gsm.kri = "1.0.0")
  cache <- local_testdata_env(server, function() installed)

  env <- new.env()
  .register_testdata(env)
  expect_message(lSource <- env$lSource, "Building local gsm test data")
  expect_equal(lSource$x, "local")
  expect_equal(builder$calls(), 1)
  dir <- file.path(cache, "local", fresh_inputs_hash(installed))
  expect_true(file.exists(file.path(dir, "snapshot.json")))

  # Simulated restart: new handle and memo, same state file and cache.
  clear_testdata_snapshots()
  server$reset_requests()
  env2 <- new.env()
  .register_testdata(env2)
  expect_message(lSource <- env2$lSource, "Using local gsm test data")
  expect_equal(lSource$x, "local")
  expect_equal(builder$calls(), 1)
  expect_length(server$requests(), 0)

  # Later checks in the same session don't repeat the message.
  expect_no_message(gsm_testdata()$refresh())
})

test_that("an existing local build is used without the builder option (#223)", {
  builder <- local_fake_builder(list(lSource = list(x = "local")))
  withr::local_options(gsm.testdata_builder = builder$fn)
  server <- local_published()
  installed <- helper_pkg_state(gsm.core = "1.0.0", gsm.kri = "1.0.0")
  cache <- local_testdata_env(server, function() installed)
  env <- new.env()
  .register_testdata(env)
  suppressMessages(env$lSource)

  # New process without the option (e.g. R CMD INSTALL), fresh state.
  withr::local_options(gsm.testdata_builder = NULL)
  clear_testdata_snapshots()
  unlink(file.path(cache, "testdata-state.rds"))
  env2 <- new.env()
  .register_testdata(env2)
  expect_message(lSource <- env2$lSource, "Using local gsm test data")
  expect_equal(lSource$x, "local")
  expect_equal(builder$calls(), 1)
})

test_that("the local data message is skipped in R CMD check (#223)", {
  builder <- local_fake_builder()
  withr::local_options(gsm.testdata_builder = builder$fn)
  server <- local_published()
  cache <- local_testdata_env(server, function() {
    helper_pkg_state(gsm.core = "1.0.0", gsm.kri = "1.0.0")
  })
  env <- new.env()
  .register_testdata(env)
  suppressMessages(env$lSource)
  clear_testdata_snapshots()
  unlink(file.path(cache, "testdata-state.rds"))
  withr::local_envvar(`_R_CHECK_PACKAGE_NAME_` = "gsm.core")
  env2 <- new.env()
  .register_testdata(env2)
  expect_no_message(env2$lSource)
})

test_that(".testdata_local_match() finds builds for the installed packages (#223)", {
  root <- withr::local_tempdir()
  installed <- helper_pkg_state(gsm.core = "1.0.0", gsm.kri = "1.0.0")
  local_mocked_bindings(.testdata_installed = function(pkgs) installed[pkgs])
  expect_null(.testdata_local_match(file.path(root, "missing")))

  write_build <- function(name) {
    dir <- file.path(root, name)
    dir.create(dir)
    saveRDS(1, file.path(dir, "x.rds"))
    write_snapshot_json(dir, list(x = "x.rds"), key = "k", packages = installed)
    dir
  }
  write_build("stale")
  expect_null(.testdata_local_match(root))
  dir <- write_build(fresh_inputs_hash(installed))
  expect_identical(.testdata_local_match(root), dir)
})

test_that("a no-match with a local package builds instead of erroring (#219)", {
  builder <- local_fake_builder()
  withr::local_options(gsm.testdata_builder = builder$fn)
  server <- local_published()
  cache <- local_testdata_env(server, function() {
    helper_pkg_state(gsm.core = "1.0.0", gsm.kri = "0.5.0")
  })
  expect_message(tag <- helper_run_checker(cache), "Building")
  expect_match(tag, "^data-[0-9a-f]{12}$")
  expect_equal(builder$calls(), 1)
})

test_that("builder errors are surfaced with the parent condition (#219)", {
  withr::local_options(gsm.testdata_builder = function(...) stop("boom"))
  server <- local_published()
  cache <- local_testdata_env(server, function() {
    helper_pkg_state(gsm.core = "1.0.0", gsm.kri = "1.0.0")
  })
  err <- expect_error(
    suppressMessages(helper_run_checker(cache)),
    "Failed to build local gsm test data"
  )
  expect_match(conditionMessage(err$parent), "boom")
})

test_that("rebuild_local_testdata() replaces the cached build (#219)", {
  builder <- local_fake_builder(list(lSource = list(x = "v1")))
  withr::local_options(gsm.testdata_builder = builder$fn)
  server <- local_published()
  local_testdata_env(server, function() {
    helper_pkg_state(gsm.core = "1.0.0", gsm.kri = "1.0.0")
  })
  env <- new.env()
  .register_testdata(env, cache = cachem::cache_mem())
  expect_equal(suppressMessages(env$lSource$x), "v1")

  builder$set_objects(list(lSource = list(x = "v2")))
  suppressMessages(rebuild_local_testdata())
  expect_equal(builder$calls(), 2)
  expect_equal(suppressMessages(env$lSource$x), "v2")

  withr::local_options(gsm.testdata_builder = NULL)
  expect_error(rebuild_local_testdata(), "gsm.testdata_builder")
})

test_that("a pinned tag or snapshot folder takes priority (#219)", {
  builder <- local_fake_builder()
  withr::local_options(gsm.testdata_builder = builder$fn)
  server <- local_published()
  fp <- server$release(list(lSource = list(x = "pinned")))
  tag <- paste0("data-", substr(fp, 1, 12))
  cache <- local_testdata_env(server, function() {
    helper_pkg_state(gsm.core = "1.0.0", gsm.kri = "1.0.0")
  })
  use_testdata_tag(tag)
  expect_equal(helper_run_checker(cache), tag)
  use_testdata_tag(NULL)

  env <- new.env()
  .register_testdata(env)
  use_testdata_snapshot(file.path(server$root, tag))
  expect_equal(env$lSource$x, "pinned")
  expect_equal(builder$calls(), 0)
})

test_that("a release matching a local build is copied, not downloaded (#219)", {
  objects <- list(lSource = list(x = "same"))
  builder <- local_fake_builder(objects)
  withr::local_options(gsm.testdata_builder = builder$fn)
  server <- local_fake_releases()
  fp <- server$release(objects)
  server$index(helper_fake_build(
    fp,
    helper_pkg_state(gsm.core = c("1.0.0", "s1"))
  ))
  installed <- helper_pkg_state(gsm.core = "1.0.0")
  cache <- local_testdata_env(server, function() installed)

  expect_equal(
    suppressMessages(helper_run_checker(cache)),
    paste0("data-", substr(fp, 1, 12))
  )
  index <- jsonlite::read_json(file.path(cache, "local", "index.json"))
  expect_equal(index[[fp]], fresh_inputs_hash(installed))

  # Now the published packages are installed; the release is served from the
  # local build.
  installed <- helper_pkg_state(gsm.core = c("1.0.0", "s1"))
  clear_testdata_snapshots()
  server$reset_requests()
  env <- new.env()
  .register_testdata(env)
  expect_equal(env$lSource$x, "same")
  expect_false(any(grepl("releases/download", server$requests())))
})

test_that("an unavailable builder doesn't block published or cached data (#219)", {
  server <- local_published()
  installed <- helper_pkg_state(
    gsm.core = c("1.0.0", "s1"),
    gsm.kri = c("1.0.0", "k1")
  )
  cache <- local_testdata_env(server, function() installed)
  withr::local_options(gsm.testdata_builder = "notapkg123::fn")
  # Exact match: published data, builder never resolved.
  expect_match(helper_run_checker(cache), "^data-")

  # Cached local build: reused without resolving the builder.
  builder <- local_fake_builder()
  installed <- helper_pkg_state(gsm.core = "1.0.0", gsm.kri = "1.0.0")
  withr::local_options(gsm.testdata_builder = builder$fn)
  tag <- suppressMessages(helper_run_checker(cache))
  withr::local_options(gsm.testdata_builder = "notapkg123::fn")
  expect_equal(suppressMessages(helper_run_checker(cache)), tag)
  expect_equal(builder$calls(), 1)
})

test_that("a rebuild evicts snapshots memoized for the old data (#219)", {
  builder <- local_fake_builder(list(lSource = list(x = "v1")))
  withr::local_options(gsm.testdata_builder = builder$fn)
  server <- local_published()
  cache <- local_testdata_env(server, function() {
    helper_pkg_state(gsm.core = "1.0.0", gsm.kri = "1.0.0")
  })
  old_tag <- suppressMessages(helper_run_checker(cache))
  expect_false(is.null(gsm$testdata_snapshots[[old_tag]]))

  builder$set_objects(list(lSource = list(x = "v2")))
  .register_testdata(new.env(), cache = cachem::cache_mem())
  suppressMessages(rebuild_local_testdata())
  expect_null(gsm$testdata_snapshots[[old_tag]])
  # The old tag no longer resolves to the rebuilt folder.
  expect_null(.testdata_local_find(old_tag))
})

test_that("a damaged local copy of a release falls back to downloading (#219)", {
  objects <- list(lSource = list(x = "same"))
  builder <- local_fake_builder(objects)
  withr::local_options(gsm.testdata_builder = builder$fn)
  server <- local_fake_releases()
  fp <- server$release(objects)
  server$index(helper_fake_build(
    fp,
    helper_pkg_state(gsm.core = c("1.0.0", "s1"))
  ))
  installed <- helper_pkg_state(gsm.core = "1.0.0")
  cache <- local_testdata_env(server, function() installed)
  suppressMessages(helper_run_checker(cache))
  local_dir <- file.path(cache, "local", fresh_inputs_hash(installed))
  saveRDS(list(x = "corrupt"), file.path(local_dir, "lSource.rds"))

  withr::local_options(gsm.testdata_builder = NULL)
  installed <- helper_pkg_state(gsm.core = c("1.0.0", "s1"))
  clear_testdata_snapshots()
  server$reset_requests()
  env <- new.env()
  .register_testdata(env)
  expect_equal(env$lSource$x, "same")
  expect_true(any(grepl("releases/download", server$requests())))
})

test_that("a damaged local-only build still errors (#219)", {
  builder <- local_fake_builder()
  withr::local_options(gsm.testdata_builder = builder$fn)
  server <- local_published()
  installed <- helper_pkg_state(gsm.core = "1.0.0", gsm.kri = "1.0.0")
  local_testdata_env(server, function() installed)
  env <- new.env()
  .register_testdata(env)
  suppressMessages(env$lSource)
  dir <- gsm_testdata()$state$get("lookup")$dir
  saveRDS("corrupt", file.path(dir, "lSource.rds"))
  clear_testdata_snapshots()
  env2 <- new.env()
  .register_testdata(env2, cache = cachem::cache_mem())
  expect_error(suppressMessages(env2$lSource), "Digest mismatch")
})

test_that("an index with no builds builds locally (#219)", {
  builder <- local_fake_builder()
  withr::local_options(gsm.testdata_builder = builder$fn)
  server <- local_fake_releases()
  jsonlite::write_json(
    list(
      format = 2,
      packages = "gsm.core",
      fingerprints = setNames(list(), character()),
      builds = list()
    ),
    file.path(server$root, "index.json"),
    auto_unbox = TRUE
  )
  cache <- local_testdata_env(server, function() {
    helper_pkg_state(gsm.core = "1.0.0")
  })
  expect_match(suppressMessages(helper_run_checker(cache)), "^data-")
  expect_equal(builder$calls(), 1)
})

test_that("a build finished by another session first is kept (#219)", {
  dir <- file.path(withr::local_tempdir(), "local", "abc")
  other <- local_fake_builder(list(lSource = list(x = "other")))
  mine <- local_fake_builder(list(lSource = list(x = "mine")))
  racing <- function(output_dir, ...) {
    # Another session publishes while this one builds.
    other$fn(dir, overwrite = TRUE, allow_local = TRUE)
    mine$fn(output_dir, ...)
  }
  suppressMessages(.testdata_local_build(dir, racing))
  expect_equal(readRDS(file.path(dir, "lSource.rds"))$x, "other")

  suppressMessages(.testdata_local_build(dir, racing, rebuild = TRUE))
  expect_equal(readRDS(file.path(dir, "lSource.rds"))$x, "mine")
  expect_equal(list.files(dirname(dir)), "abc")
})
