test_that("keep_fresh() creates read-only bindings that call setters lazily (#206)", {
  h <- new_counted_handle()
  expect_equal(h$calls$n, 0)
  expect_equal(h$env$b$k, "v1")
  h$env$b
  expect_equal(h$calls$n, 1)
  expect_error(assign("b", 1, envir = h$env), "read-only")
})

test_that("check modes control when the checker reruns (#206)", {
  key <- "v1"
  checks <- 0
  checker <- function(state) {
    checks <<- checks + 1
    key
  }
  env <- new.env()
  handle <- keep_fresh(checker, list(x = function(k) k), env, check = "access")
  expect_equal(env$x, "v1")
  key <- "v2"
  expect_equal(env$x, "v2")
  expect_equal(handle$key(), "v2")

  checks <- 0
  handle <- keep_fresh(checker, list(x = function(k) k), env)
  env$x
  env$x
  expect_equal(checks, 1)
  handle$refresh()
  handle$invalidate()
  env$x
  expect_equal(checks, 3)

  checks <- 0
  keep_fresh(checker, list(x = function(k) k), env, check = 0)
  env$x
  env$x
  expect_equal(checks, 2)
})

test_that("keep_fresh() validates its arguments (#206)", {
  env <- new.env()
  ok <- list(x = function(k) k)
  expect_error(keep_fresh(function(s) 1, ok, env, check = "never"), "check")
  expect_error(keep_fresh(function(s) 1, ok, env, cache = list()), "cachem")
  expect_error(
    keep_fresh(function(s) 1, ok, env, state = list()),
    "state store"
  )
})

test_that("a disk cache and state file persist across keep_fresh() calls (#206)", {
  dir <- withr::local_tempdir()
  calls <- 0
  setters <- list(x = function(k) {
    calls <<- calls + 1
    k
  })
  checker <- function(state) {
    state$set("n", state$get("n", 0) + 1)
    "v1"
  }
  for (i in 1:2) {
    env <- new.env()
    keep_fresh(
      checker,
      setters,
      env,
      cache = cachem::cache_disk(file.path(dir, "values")),
      state = state_file(function() file.path(dir, "state.rds"))
    )
    env$x
  }
  expect_equal(calls, 1)
  expect_equal(readRDS(file.path(dir, "state.rds"))$n, 2)
})

test_that("handle methods manage cache, state, and print (#206)", {
  first <- cachem::cache_mem()
  h <- new_counted_handle(cache = first, state = state_memory())
  h$env$b
  expect_message(print(h$handle), "v1")
  expect_s3_class(h$handle$state, "FreshState")
  expect_null(h$handle$snapshot)

  second <- cachem::cache_mem()
  h$handle$set_cache(second)
  expect_identical(h$handle$cache, second)
  h$env$b
  expect_equal(h$calls$n, 1)
  h$handle$reset()
  expect_null(h$handle$key())
  h$env$b
  expect_equal(h$calls$n, 2)
  expect_length(second$keys(), 1)

  expect_error(h$handle$cache <- first)
  expect_error(h$handle$state <- state_memory(), "read-only")
  expect_error(h$handle$snapshot <- NULL, "use_snapshot")
})

test_that("handles save and read snapshots (#206)", {
  src <- new_counted_handle()
  dir <- withr::local_tempdir()
  src$handle$save_snapshot(dir)

  h <- new_counted_handle(key = "live", snapshot_path = dir)
  expect_equal(h$env$b$k, "v1")
  expect_equal(h$env$b$k, "v1")
  expect_equal(h$calls$n, 0)
})

test_that("state stores get, set, and reset (#206)", {
  path <- withr::local_tempfile(fileext = ".rds")
  for (state in list(state_file(path), state_memory())) {
    expect_equal(state$get("a", "default"), "default")
    state$set("a", 2)
    expect_equal(state$get("a"), 2)
    state$reset()
    expect_null(state$get("a"))
  }
  expect_error(state_file(path)$path <- "x", "read-only")
})

test_that("fresh_exports() builds export directives (#206)", {
  expect_equal(fresh_exports(c("a", "b")), c("export(a)", "export(b)"))
})

test_that(".fresh_move() errors when it can't write (#206)", {
  expect_error(
    suppressWarnings(.fresh_move(tempfile(), withr::local_tempfile())),
    "Failed to write"
  )
})
