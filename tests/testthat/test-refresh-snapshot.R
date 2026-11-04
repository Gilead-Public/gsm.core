test_that("save_snapshot() writes every value plus snapshot.json (#206)", {
  h <- new_counted_handle()
  dir <- file.path(withr::local_tempdir(), "snap")
  info <- h$handle$save_snapshot(dir, metadata = list(note = "hi"))

  expect_setequal(list.files(dir), c("a.rds", "b.rds", "snapshot.json"))
  expect_equal(readRDS(file.path(dir, "a.rds")), h$env$a)
  json <- jsonlite::read_json(file.path(dir, "snapshot.json"))
  expect_equal(json$refresh_snapshot, 1L)
  expect_equal(json$key, "v1")
  expect_equal(json$metadata$note, "hi")
  expect_equal(
    json$objects$a$sha256,
    unname(tools::sha256sum(file.path(dir, "a.rds")))
  )
  expect_equal(json$objects$a$file, "a.rds")
  expect_equal(info$key, "v1")
})

test_that("save_snapshot() can save a subset and record package versions (#206)", {
  h <- new_counted_handle()
  dir <- withr::local_tempdir()
  local_mocked_bindings(package_versions = function(packages) {
    pkg_state(gsm.core = c("2.1.0", "abc"))[packages]
  })
  h$handle$save_snapshot(dir, names = "a", packages = "gsm.core")
  json <- read_snapshot(dir)
  expect_named(json$objects, "a")
  expect_equal(json$packages$gsm.core$version, "2.1.0")
  expect_equal(json$packages$gsm.core$remote_sha, "abc")
  expect_error(h$handle$save_snapshot(dir, names = "nope"), "nope")
})

test_that("save_snapshot() refuses non-string keys unless given one (#206)", {
  h <- new_counted_handle(key = list(a = 1))
  dir <- withr::local_tempdir()
  expect_error(h$handle$save_snapshot(dir), "key")
  h$handle$save_snapshot(dir, key = "custom")
  expect_equal(read_snapshot(dir)$key, "custom")
})

test_that("use_snapshot() serves values from disk, bypassing checker and cache (#206)", {
  src <- new_counted_handle()
  dir <- withr::local_tempdir()
  src$handle$save_snapshot(dir)

  checks <- 0
  cache <- cachem::cache_mem()
  env <- new.env()
  handle <- keep_fresh(
    checker = function(state) {
      checks <<- checks + 1
      "other"
    },
    setters = list(a = function(k) stop("no"), b = function(k) stop("no")),
    env = env,
    cache = cache
  )
  handle$use_snapshot(dir)
  expect_equal(env$a, src$env$a)
  expect_equal(env$b$k, "v1")
  expect_equal(handle$key(), "v1")
  expect_equal(checks, 0)
  expect_length(cache$keys(), 0)
  expect_equal(handle$snapshot$dir, normalizePath(dir, winslash = "/"))
})

test_that("use_snapshot(NULL) returns to normal operation (#206)", {
  src <- new_counted_handle(key = "snap")
  dir <- withr::local_tempdir()
  src$handle$save_snapshot(dir)

  h <- new_counted_handle(key = "live")
  h$handle$use_snapshot(dir)
  expect_equal(h$env$b$k, "snap")
  h$handle$use_snapshot(NULL)
  expect_null(h$handle$snapshot)
  expect_equal(h$env$b$k, "live")
})

test_that("keep_fresh(snapshot = ) starts in snapshot mode (#206)", {
  src <- new_counted_handle()
  dir <- withr::local_tempdir()
  src$handle$save_snapshot(dir)
  h <- new_counted_handle(key = "live", snapshot = dir)
  expect_equal(h$env$b$k, "v1")
  expect_equal(h$calls$n, 0)
})

test_that("use_snapshot() verifies checksums and reports missing objects (#206)", {
  src <- new_counted_handle()
  dir <- withr::local_tempdir()
  src$handle$save_snapshot(dir, names = "a")
  h <- new_counted_handle()
  h$handle$use_snapshot(dir)
  expect_error(h$env$b, "\"b\".*not in the snapshot")

  saveRDS(iris, file.path(dir, "a.rds"))
  h$handle$use_snapshot(dir)
  expect_error(h$env$a, "Checksum mismatch")
})

test_that("use_snapshot() errors clearly on bad folders (#206)", {
  h <- new_counted_handle()
  expect_error(
    h$handle$use_snapshot(file.path(tempdir(), "does-not-exist")),
    "does not exist"
  )
  expect_error(h$handle$use_snapshot(withr::local_tempdir()), "snapshot.json")

  dir <- withr::local_tempdir()
  jsonlite::write_json(
    list(refresh_snapshot = 99),
    file.path(dir, "snapshot.json"),
    auto_unbox = TRUE
  )
  expect_error(h$handle$use_snapshot(dir), "newer version of refresh")
})

test_that("use_snapshot() reports packages newer than the snapshot (#206)", {
  src <- new_counted_handle()
  dir <- withr::local_tempdir()
  local_mocked_bindings(package_versions = function(packages) {
    pkg_state(gsm.core = "2.1.0", gsm.kri = "1.0.0")[packages]
  })
  src$handle$save_snapshot(dir, packages = c("gsm.core", "gsm.kri"))

  local_mocked_bindings(package_versions = function(packages) {
    pkg_state(gsm.core = "2.2.0", gsm.kri = "1.0.0")[packages]
  })
  h <- new_counted_handle()
  expect_message(h$handle$use_snapshot(dir), "gsm.core")
  expect_no_message(h$handle$use_snapshot(dir, check_packages = FALSE))
})

test_that("objects can map to differently named files (#206)", {
  dir <- withr::local_tempdir()
  saveRDS(mtcars, file.path(dir, "cars-data.rds"))
  write_snapshot_json(
    dir,
    objects = list(cars = "cars-data.rds"),
    key = "k"
  )
  env <- new.env()
  handle <- keep_fresh(
    function(s) "x",
    list(cars = function(k) NULL),
    env,
    snapshot = dir
  )
  expect_equal(env$cars, mtcars)
})

# Package versions ------------------------------------------------------------

test_that("package_versions() reads Version and RemoteSha (#206)", {
  v <- package_versions(c("cachem", "definitely.not.a.package"))
  expect_equal(v$cachem$version, as.character(utils::packageVersion("cachem")))
  expect_true(is.na(v$definitely.not.a.package$version))
})

test_that("packages_newer() compares versions, then SHAs (#206)", {
  recorded <- pkg_state(
    gsm.core = c("2.1.0", "aaa"),
    gsm.kri = "1.7.0"
  )
  newer <- function(...) packages_newer(pkg_state(...), recorded)
  expect_equal(newer(gsm.core = c("2.1.0", "aaa")), character())
  expect_equal(newer(gsm.core = "2.0.0"), character())
  expect_equal(newer(gsm.core = "2.1.0.9000"), "gsm.core")
  expect_equal(newer(gsm.core = c("2.1.0", "bbb")), "gsm.core")
  expect_equal(newer(gsm.core = "2.1.0"), character())
  expect_equal(newer(gsm.kri = c("1.7.0", "zzz")), character())
  expect_equal(newer(gsm.core = NA_character_), character())
  expect_equal(newer(gsm.new = "9.9.9"), character())
  expect_equal(
    newer(gsm.core = "3.0.0", gsm.kri = "1.8.0"),
    c("gsm.core", "gsm.kri")
  )
})

test_that("packages_changed() tracks installed packages in checker state (#206)", {
  state <- state_memory()
  installed <- pkg_state(a = "1.0.0")
  local_mocked_bindings(package_versions = function(packages) {
    installed[packages]
  })

  expect_true(packages_changed(state, "a"))
  expect_false(packages_changed(state, "a"))
  installed <- pkg_state(a = "1.0.1")
  expect_true(packages_changed(state, "a"))
  expect_false(packages_changed(state, "a"))
  # Separate slots don't interfere.
  expect_true(packages_changed(state, "a", slot = "other"))
})
