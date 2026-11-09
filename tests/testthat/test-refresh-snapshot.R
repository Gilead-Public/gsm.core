test_that("save_snapshot() writes values, packages, and metadata (#206)", {
  h <- new_counted_handle(snapshot_names = c(a = "alpha"))
  dir <- withr::local_tempdir()
  local_mocked_bindings(package_versions = function(packages) {
    helper_pkg_state(gsm.core = c("2.1.0", "abc"))[packages]
  })
  info <- h$handle$save_snapshot(
    dir,
    packages = "gsm.core",
    metadata = list(note = "hi")
  )

  expect_setequal(list.files(dir), c("alpha.rds", "b.rds", "snapshot.json"))
  json <- read_snapshot(dir)
  expect_equal(json$key, "v1")
  expect_equal(json$metadata$note, "hi")
  expect_equal(json$packages$gsm.core$remote_sha, "abc")
  expect_equal(
    json$objects$alpha$sha256,
    .fresh_sha256(file.path(dir, "alpha.rds"))
  )
  expect_equal(info$key, "v1")
  expect_error(h$handle$save_snapshot(dir, names = "nope"), "nope")
})

test_that("save_snapshot() refuses non-string keys unless given one (#206)", {
  h <- new_counted_handle(key = list(a = 1))
  dir <- withr::local_tempdir()
  expect_error(h$handle$save_snapshot(dir), "key")
  h$handle$save_snapshot(dir, key = "custom", names = "b")
  expect_equal(read_snapshot(dir)$key, "custom")
})

test_that("save_snapshot() uses one key for every object (#206)", {
  n <- 0
  handle <- keep_fresh(
    checker = function(state) {
      n <<- n + 1
      paste0("v", n)
    },
    setters = list(a = function(k) k, b = function(k) k),
    env = new.env(),
    check = "access"
  )
  dir <- withr::local_tempdir()
  info <- handle$save_snapshot(dir)
  expect_equal(readRDS(file.path(dir, "a.rds")), info$key)
  expect_equal(readRDS(file.path(dir, "b.rds")), info$key)
})

test_that("use_snapshot() serves values from disk, then NULL returns to live (#206)", {
  src <- new_counted_handle(snapshot_names = c(a = "alpha"))
  dir <- withr::local_tempdir()
  src$handle$save_snapshot(dir)

  h <- new_counted_handle(key = "live", snapshot_names = c(a = "alpha"))
  h$handle$use_snapshot(dir)
  expect_equal(h$env$a, src$env$a)
  expect_equal(h$handle$key(), "v1")
  expect_equal(h$calls$n, 0)
  expect_length(h$handle$cache$keys(), 0)

  h$handle$use_snapshot(NULL)
  expect_null(h$handle$snapshot)
  expect_equal(h$env$b$k, "live")
})

test_that("use_snapshot() verifies objects (#206)", {
  src <- new_counted_handle()
  dir <- withr::local_tempdir()
  src$handle$save_snapshot(dir, names = "a")
  h <- new_counted_handle()
  h$handle$use_snapshot(dir)
  expect_error(h$env$b, "\"b\".*not in the snapshot")

  saveRDS(iris, file.path(dir, "a.rds"))
  expect_error(h$env$a, "Checksum mismatch")
  unlink(file.path(dir, "a.rds"))
  expect_error(h$env$a, "is missing")
})

test_that("use_snapshot() errors clearly on bad folders (#206)", {
  h <- new_counted_handle()
  expect_error(
    h$handle$use_snapshot(file.path(tempdir(), "does-not-exist")),
    "does not exist"
  )
  expect_error(h$handle$use_snapshot(withr::local_tempdir()), "snapshot.json")

  bad_json <- function(x) {
    dir <- withr::local_tempdir(.local_envir = parent.frame())
    jsonlite::write_json(x, file.path(dir, "snapshot.json"), auto_unbox = TRUE)
    dir
  }
  expect_error(h$handle$use_snapshot(bad_json(list(key = "k"))), "refresh_snapshot")
  expect_error(
    h$handle$use_snapshot(bad_json(list(refresh_snapshot = 99))),
    "newer version of refresh"
  )
  expect_error(
    h$handle$use_snapshot(bad_json(list(refresh_snapshot = 1))),
    "string"
  )
  expect_error(
    write_snapshot_json(withr::local_tempdir(), list(a = "a.rds"), "k"),
    "does not exist"
  )
})

test_that("use_snapshot() reports packages newer than the snapshot (#206)", {
  src <- new_counted_handle()
  dir <- withr::local_tempdir()
  local_mocked_bindings(package_versions = function(packages) {
    helper_pkg_state(gsm.core = "2.1.0")[packages]
  })
  src$handle$save_snapshot(dir, packages = "gsm.core")

  local_mocked_bindings(package_versions = function(packages) {
    helper_pkg_state(gsm.core = "2.2.0")[packages]
  })
  h <- new_counted_handle()
  expect_message(h$handle$use_snapshot(dir), "gsm.core")
  expect_no_message(h$handle$use_snapshot(dir, check_packages = FALSE))
})

# Package versions ------------------------------------------------------------

test_that("package_versions() reads Version and RemoteSha (#206)", {
  v <- package_versions(c("cachem", "definitely.not.a.package"))
  expect_equal(v$cachem$version, as.character(utils::packageVersion("cachem")))
  expect_true(is.na(v$definitely.not.a.package$version))
})

test_that(".fresh_packages_newer() compares versions, then SHAs (#206)", {
  recorded <- helper_pkg_state(gsm.core = c("2.1.0", "aaa"), gsm.kri = "1.7.0")
  newer <- function(...) .fresh_packages_newer(helper_pkg_state(...), recorded)
  expect_equal(newer(gsm.core = c("2.1.0", "aaa")), character())
  expect_equal(newer(gsm.core = "2.0.0"), character())
  expect_equal(newer(gsm.core = c("2.1.0", "bbb")), "gsm.core")
  expect_equal(newer(gsm.core = NA_character_), character())
  expect_equal(newer(gsm.new = "9.9.9"), character())
  expect_equal(
    newer(gsm.core = "3.0.0", gsm.kri = "1.8.0"),
    c("gsm.core", "gsm.kri")
  )
})

test_that(".fresh_packages_changed() tracks installed packages in checker state (#206)", {
  state <- state_memory()
  installed <- helper_pkg_state(a = "1.0.0")
  local_mocked_bindings(package_versions = function(packages) installed[packages])

  expect_true(.fresh_packages_changed(state, "a"))
  expect_false(.fresh_packages_changed(state, "a"))
  installed <- helper_pkg_state(a = "1.0.1")
  expect_true(.fresh_packages_changed(state, "a"))
})
