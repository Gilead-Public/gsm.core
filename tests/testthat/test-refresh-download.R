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
