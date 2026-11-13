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
    json$objects$alpha$digest,
    fresh_digest(readRDS(file.path(dir, "alpha.rds")))
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

  h$handle$reset()
  copy <- withr::local_tempdir()
  h$handle$save_snapshot(copy)
  expect_equal(read_snapshot(copy)$key, "v1")

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
  expect_error(h$env$a, "Digest mismatch")
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
  expect_error(
    h$handle$use_snapshot(bad_json(list(key = "k"))),
    "refresh_snapshot"
  )
  expect_error(
    h$handle$use_snapshot(bad_json(list(refresh_snapshot = 99))),
    "newer version of refresh"
  )
  expect_error(
    h$handle$use_snapshot(bad_json(list(refresh_snapshot = 1, key = "k"))),
    "format 1, which is no longer"
  )
  expect_error(
    h$handle$use_snapshot(bad_json(list(refresh_snapshot = 2))),
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
  local_mocked_bindings(package_versions = function(packages) {
    installed[packages]
  })

  expect_true(.fresh_packages_changed(state, "a"))
  expect_false(.fresh_packages_changed(state, "a"))
  installed <- helper_pkg_state(a = "1.0.1")
  expect_true(.fresh_packages_changed(state, "a"))
})

test_that(".fresh_sha256() treats CRLF as LF in text files (#215)", {
  dir <- withr::local_tempdir()
  lf <- file.path(dir, "lf.txt")
  crlf <- file.path(dir, "crlf.txt")
  writeBin(charToRaw("a,b\n1,2\n"), lf)
  writeBin(charToRaw("a,b\r\n1,2\r\n"), crlf)
  expect_identical(
    .fresh_sha256(lf),
    digest::digest(file = lf, algo = "sha256")
  )
  expect_identical(.fresh_sha256(crlf), .fresh_sha256(lf))
})

test_that(".fresh_sha256() hashes files with NUL bytes as-is (#215)", {
  path <- withr::local_tempfile()
  writeBin(as.raw(c(0x00, 0x0d, 0x0a, 0x41)), path)
  expect_identical(
    .fresh_sha256(path),
    digest::digest(file = path, algo = "sha256")
  )
})

test_that("fresh_digest() ignores how an object was saved (#216)", {
  x <- list(a = 1:10, b = mtcars)
  roundtrip <- function(...) {
    path <- withr::local_tempfile(fileext = ".rds")
    saveRDS(x, path, ...)
    fresh_digest(readRDS(path))
  }
  expect_match(fresh_digest(x), "^[0-9a-f]{64}$")
  expect_identical(roundtrip(), fresh_digest(x))
  expect_identical(roundtrip(version = 2), fresh_digest(x))
  expect_identical(roundtrip(compress = "xz"), fresh_digest(x))
  expect_identical(roundtrip(compress = FALSE), fresh_digest(x))
  # ALTREP compact sequence vs. materialized vector.
  expect_identical(fresh_digest(1:10), fresh_digest(c(1:5, 6:10)))
  expect_false(identical(fresh_digest(x), fresh_digest(list(a = 1:10))))
})

test_that("fresh_fingerprint() ignores order and locale (#216)", {
  d <- list(b = strrep("b", 64), a = strrep("a", 64), B = strrep("c", 64))
  fp <- fresh_fingerprint(d)
  expect_match(fp, "^[0-9a-f]{64}$")
  expect_identical(fresh_fingerprint(rev(d)), fp)
  expect_identical(fresh_fingerprint(unlist(d)), fp)
  expect_identical(
    fp,
    digest::digest(
      paste0(
        "B:",
        strrep("c", 64),
        "
",
        "a:",
        strrep("a", 64),
        "
",
        "b:",
        strrep("b", 64)
      ),
      algo = "sha256",
      serialize = FALSE
    )
  )
  withr::with_locale(c(LC_COLLATE = "en_US.UTF-8"), {
    expect_identical(fresh_fingerprint(d), fp)
  })
  expect_false(identical(fresh_fingerprint(d[-1]), fp))
})

test_that("fresh_fingerprint() rejects bad digests (#216)", {
  expect_error(fresh_fingerprint(list()), "digests")
  expect_error(fresh_fingerprint(c("x", "y")), "digests")
  expect_error(fresh_fingerprint(c(a = "x", a = "y")), "digests")
  expect_error(fresh_fingerprint(list(a = c("x", "y"))), "digests")
  expect_error(fresh_fingerprint(list(a = 1)), "digests")
})

test_that("format 2 round-trips through write_snapshot_json() (#216)", {
  dir <- withr::local_tempdir()
  saveRDS(mtcars, file.path(dir, "cars.rds"), version = 2, compress = "xz")
  info <- write_snapshot_json(dir, c(cars = "cars.rds"), key = "k")
  snap <- read_snapshot(dir)
  expect_equal(snap$refresh_snapshot, 2)
  expect_equal(snap$objects$cars$digest, fresh_digest(mtcars))
  expect_null(snap$objects$cars$sha256)
  expect_equal(.snapshot_read_object(snap, "cars"), mtcars)

  # Resaving the same object another way still verifies; a changed one fails.
  saveRDS(mtcars, file.path(dir, "cars.rds"))
  expect_equal(.snapshot_read_object(snap, "cars"), mtcars)
  saveRDS(mtcars[-1, ], file.path(dir, "cars.rds"))
  expect_error(.snapshot_read_object(snap, "cars"), "Digest mismatch")
})

test_that("fresh_inputs_hash() ignores package order (#216)", {
  pkgs <- helper_pkg_state(b = "1.0.0", a = c("2.0.0", "abc"))
  expect_identical(fresh_inputs_hash(pkgs), fresh_inputs_hash(rev(pkgs)))
  expect_identical(
    fresh_inputs_hash(pkgs),
    digest::digest(
      "a 2.0.0 abc
b 1.0.0 NA",
      algo = "sha256",
      serialize = FALSE
    )
  )
})
