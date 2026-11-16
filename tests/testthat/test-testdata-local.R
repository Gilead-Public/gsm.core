# Local test data builds (#219).

# A fake builder that writes a bundle of `objects` and counts its calls.
local_fake_builder <- function(objects = list(lSource = list(x = 1))) {
  calls <- 0L
  fn <- function(output_dir, overwrite = FALSE, allow_local = FALSE) {
    stopifnot(isTRUE(overwrite), isTRUE(allow_local))
    calls <<- calls + 1L
    dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
    files <- rlang::set_names(paste0(names(objects), ".rds"), names(objects))
    for (name in names(objects)) {
      saveRDS(objects[[name]], file.path(output_dir, files[[name]]))
    }
    write_snapshot_json(output_dir, as.list(files), key = "local")
  }
  list(
    fn = fn,
    calls = function() calls,
    set_objects = function(x) objects <<- x
  )
}

# One published build at gsm.core 1.0.0 (sha s1) plus gsm.kri 1.0.0 (k1).
local_published <- function(env = parent.frame()) {
  server <- local_fake_releases(env)
  fp <- server$release(list(lSource = list(x = "published")))
  server$index(helper_fake_build(
    fp,
    helper_pkg_state(gsm.core = c("1.0.0", "s1"), gsm.kri = c("1.0.0", "k1"))
  ))
  server
}

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
  server$index(helper_fake_build(fp, helper_pkg_state(gsm.core = c("1.0.0", "s1"))))
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
