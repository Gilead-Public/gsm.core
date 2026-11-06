test_that("keep_fresh() creates read-only bindings that call setters lazily (#206)", {
  env <- new.env()
  calls <- 0
  keep_fresh(
    checker = function(state) "v1",
    setters = list(x = function(key) {
      calls <<- calls + 1
      paste("x", key)
    }),
    env = env
  )
  expect_equal(calls, 0)
  expect_equal(env$x, "x v1")
  expect_equal(env$x, "x v1")
  expect_equal(calls, 1)
  expect_error(assign("x", 1, envir = env), "read-only")
})

test_that("keep_fresh() reruns setters only when the key changes (#206)", {
  env <- new.env()
  key <- "v1"
  calls <- 0
  handle <- keep_fresh(
    checker = function(state) key,
    setters = list(x = function(k) {
      calls <<- calls + 1
      k
    }),
    env = env,
    check = "access"
  )
  expect_equal(env$x, "v1")
  expect_equal(env$x, "v1")
  expect_equal(calls, 1)
  key <- "v2"
  expect_equal(env$x, "v2")
  expect_equal(calls, 2)
  expect_equal(handle$key(), "v2")
})

test_that("check = 'session' runs the checker once until refresh() (#206)", {
  env <- new.env()
  checks <- 0
  handle <- keep_fresh(
    checker = function(state) {
      checks <<- checks + 1
      "v1"
    },
    setters = list(x = function(k) k, y = function(k) k),
    env = env
  )
  env$x
  env$y
  env$x
  expect_equal(checks, 1)
  handle$refresh()
  expect_equal(checks, 2)
})

test_that("numeric check re-runs the checker after the interval (#206)", {
  env <- new.env()
  checks <- 0
  keep_fresh(
    checker = function(state) {
      checks <<- checks + 1
      "v1"
    },
    setters = list(x = function(k) k),
    env = env,
    check = 0
  )
  env$x
  env$x
  expect_equal(checks, 2)
})

test_that("keep_fresh() validates its arguments (#206)", {
  env <- new.env()
  ok <- list(x = function(k) k)
  expect_error(keep_fresh("a", ok, env))
  expect_error(keep_fresh(function(s) 1, list(function(k) k), env))
  expect_error(keep_fresh(function(s) 1, ok, list()))
  expect_error(keep_fresh(function(s) 1, ok, env, check = "never"), "check")
  expect_error(keep_fresh(function(s) 1, ok, env, check = -1), "check")
})

test_that("keep_fresh() validates cache and state (#206)", {
  env <- new.env()
  ok <- list(x = function(k) k)
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
    paste("x", k)
  })
  checker <- function(state) {
    state$set("n", state$get("n", 0) + 1)
    "v1"
  }
  state_path <- file.path(dir, "state.rds")

  env1 <- new.env()
  keep_fresh(
    checker,
    setters,
    env1,
    cache = cachem::cache_disk(file.path(dir, "values")),
    state = state_file(state_path)
  )
  expect_equal(env1$x, "x v1")

  env2 <- new.env()
  keep_fresh(
    checker,
    setters,
    env2,
    cache = cachem::cache_disk(file.path(dir, "values")),
    state = state_file(state_path)
  )
  expect_equal(env2$x, "x v1")
  expect_equal(calls, 1)
  expect_equal(readRDS(state_path)$n, 2)
})

test_that("the handle exposes the user's cache and state (#206)", {
  env <- new.env()
  cache <- cachem::cache_mem()
  state <- state_memory()
  handle <- keep_fresh(
    function(s) {
      s$set("seen", TRUE)
      "v1"
    },
    list(x = function(k) k),
    env,
    cache = cache,
    state = state
  )
  env$x
  expect_identical(handle$cache, cache)
  expect_identical(handle$state, state)
  expect_length(handle$cache$keys(), 1)
  expect_message(print(handle), "v1")
})

test_that("reset() clears session values and state but keeps the cache (#206)", {
  env <- new.env()
  calls <- 0
  handle <- keep_fresh(
    function(s) {
      s$set("seen", TRUE)
      "v1"
    },
    list(x = function(k) {
      calls <<- calls + 1
      k
    }),
    env
  )
  env$x
  handle$reset()
  expect_null(handle$key())
  expect_null(handle$state$get("seen"))
  env$x
  expect_equal(calls, 1)
  # Clearing the cache itself is a plain cachem call.
  handle$cache$reset()
  handle$reset()
  env$x
  expect_equal(calls, 2)
})

test_that("cache eviction rebuilds values without losing state (#206)", {
  cache <- cachem::cache_mem()
  state <- state_memory()
  calls <- 0
  checker <- function(s) {
    s$set("seen", TRUE)
    "v1"
  }
  setters <- list(x = function(k) {
    calls <<- calls + 1
    k
  })
  env <- new.env()
  keep_fresh(checker, setters, env, cache = cache, state = state)
  env$x
  cache$reset()

  # Next load: value rebuilt, state intact.
  env2 <- new.env()
  keep_fresh(checker, setters, env2, cache = cache, state = state)
  env2$x
  expect_equal(calls, 2)
  expect_true(state$get("seen"))
})

test_that("state_file() and state_memory() get, set, and reset (#206)", {
  path <- withr::local_tempfile(fileext = ".rds")
  for (state in list(state_file(path), state_memory())) {
    expect_null(state$get("a"))
    expect_equal(state$get("a", "default"), "default")
    state$set("a", 2)
    expect_equal(state$get("a"), 2)
    state$reset()
    expect_null(state$get("a"))
  }
  state_file(path)$set("b", 1)
  expect_equal(state_file(path)$get("b"), 1)
  expect_equal(state_file(path)$path, path)
})

test_that("fresh_exports() builds export directives (#206)", {
  expect_equal(fresh_exports(c("a", "b")), c("export(a)", "export(b)"))
  expect_error(fresh_exports(1))
})

test_that("fetch_file() verifies checksums and uses custom requests (#206)", {
  src <- withr::local_tempfile()
  writeLines("hello", src)
  good <- .fresh_sha256(src)
  request <- function(url, dest) file.copy(src, dest, overwrite = TRUE)
  dest <- file.path(withr::local_tempdir(), "sub", "out.txt")

  fetch_file("https://example.com/f", dest, checksum = good, request = request)
  expect_equal(readLines(dest), "hello")

  expect_error(
    fetch_file(
      "https://example.com/f",
      dest,
      checksum = "bad",
      request = request
    ),
    "Checksum mismatch"
  )
  expect_error(
    fetch_file("https://example.com/f", dest, request = function(url, dest) {
      stop("boom")
    }),
    "Failed to download"
  )
})

test_that("download_setter() fetches, verifies, and reads by key (#206)", {
  server <- local_file_server()
  dir.create(file.path(server$root, "t1"))
  saveRDS(mtcars, file.path(server$root, "t1", "a.rds"))
  sha <- .fresh_sha256(file.path(server$root, "t1", "a.rds"))
  setter <- download_setter(
    url = function(key) paste0("https://x/", key, "/a.rds"),
    checksum = function(key) sha,
    request = server$request
  )
  expect_equal(setter("t1"), mtcars)
})

test_that("set_cache() swaps the cache used by later loads (#206)", {
  env <- new.env()
  calls <- 0
  first <- cachem::cache_mem()
  handle <- keep_fresh(
    function(s) "v1",
    list(x = function(k) {
      calls <<- calls + 1
      k
    }),
    env,
    cache = first
  )
  env$x
  second <- cachem::cache_mem()
  handle$set_cache(second)
  expect_identical(handle$cache, second)
  # Already-loaded values stay in memory.
  env$x
  expect_equal(calls, 1)
  handle$reset()
  env$x
  expect_equal(calls, 2)
  expect_length(first$keys(), 1)
  expect_length(second$keys(), 1)

  expect_error(handle$set_cache(list()), "cachem")
  expect_error(handle$cache <- first)
})

test_that("FreshState can be subclassed for other backends (#206)", {
  store <- new.env()
  FreshStateEnv <- R6::R6Class(
    "FreshStateEnv",
    inherit = FreshState,
    private = list(
      load = function() store$data %||% list(),
      save = function(data) store$data <- data,
      clear = function() store$data <- NULL
    )
  )
  FreshStateEnv$new()$set("a", 1)
  expect_equal(FreshStateEnv$new()$get("a"), 1)

  handle <- keep_fresh(
    function(s) "v1",
    list(x = function(k) k),
    new.env(),
    state = FreshStateEnv$new()
  )
  expect_s3_class(handle, "FreshHandle")
  expect_s3_class(handle$state, "FreshState")
  expect_error(handle$state <- state_memory(), "read-only")
})
