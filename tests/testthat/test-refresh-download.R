test_that("safely_fetch() verifies checksums and uses custom downloaders (#206)", {
  src <- withr::local_tempfile()
  writeLines("hello", src)
  good <- .fresh_sha256(src)
  downloader <- function(url, dest) file.copy(src, dest, overwrite = TRUE)
  dest <- file.path(withr::local_tempdir(), "sub", "out.txt")

  safely_fetch(
    "https://example.com/f",
    dest,
    checksum = good,
    downloader = downloader
  )
  expect_equal(readLines(dest), "hello")

  expect_error(
    safely_fetch(
      "https://example.com/f",
      dest,
      checksum = "bad",
      downloader = downloader
    ),
    "Checksum mismatch"
  )
  expect_error(
    safely_fetch(
      "https://example.com/f",
      dest,
      downloader = function(url, dest) {
        stop("boom")
      }
    ),
    "Failed to download"
  )
})

test_that("safely_fetch() defaults to fetch_binary() (#206)", {
  src <- withr::local_tempfile()
  writeLines("hello", src)
  local_mocked_bindings(
    fetch_binary = function(url, dest) file.copy(src, dest, overwrite = TRUE)
  )
  dest <- withr::local_tempfile()
  safely_fetch("https://example.com/f", dest)
  expect_equal(readLines(dest), "hello")
})

test_that("construct_fetcher() fetches, verifies, and reads by key (#206)", {
  server <- local_file_server()
  dir.create(file.path(server$root, "t1"))
  saveRDS(mtcars, file.path(server$root, "t1", "a.rds"))
  sha <- .fresh_sha256(file.path(server$root, "t1", "a.rds"))
  setter <- construct_fetcher(
    url_constructor = function(key) paste0("https://x/", key, "/a.rds"),
    checksum_finder = function(key) sha,
    downloader = server$downloader
  )
  expect_equal(setter("t1"), mtcars)
})

test_that("construct_fetcher() verifies the value's digest (#216)", {
  server <- local_file_server()
  dir.create(file.path(server$root, "t1"))
  saveRDS(mtcars, file.path(server$root, "t1", "a.rds"))
  setter <- function(digest) {
    construct_fetcher(
      url_constructor = function(key) paste0("https://x/", key, "/a.rds"),
      digest_finder = function(key) digest,
      downloader = server$downloader
    )
  }
  expect_equal(setter(fresh_digest(mtcars))("t1"), mtcars)
  expect_error(setter(fresh_digest(iris))("t1"), "Digest mismatch")
})

test_that("safely_fetch() accepts a download converted to CRLF (#215)", {
  src <- withr::local_tempfile()
  writeBin(charToRaw("a,b\r\n1,2\r\n"), src)
  lf <- withr::local_tempfile()
  writeBin(charToRaw("a,b\n1,2\n"), lf)
  dest <- file.path(withr::local_tempdir(), "out.csv")
  safely_fetch(
    "https://example.com/f",
    dest,
    checksum = digest::digest(file = lf, algo = "sha256"),
    downloader = function(url, dest) file.copy(src, dest, overwrite = TRUE)
  )
  expect_true(file.exists(dest))
})
