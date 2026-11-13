# refresh: download helpers --------------------------------------------------
#
# Part of the would-be "refresh" package; no gsm-specific code here.

#' Download a file, optionally verifying a sha256 checksum
#'
#' @param url `character(1)` URL to download.
#' @param dest `character(1)` Destination path. Written atomically.
#' @param checksum `character(1)` Expected sha256 (hex), or `NULL` to skip
#'   verification.
#' @param downloader `function` `function(url, dest)` that downloads `url` to
#'   `dest` and errors on failure. Override for authentication, APIs, etc.
#' @returns `dest`, invisibly.
#' @keywords internal
safely_fetch <- function(
  url,
  dest,
  checksum = NULL,
  downloader = fetch_binary
) {
  fs::dir_create(dirname(dest))
  tmp <- tempfile(tmpdir = dirname(dest), fileext = ".tmp")
  on.exit(unlink(tmp))

  tryCatch(
    downloader(url, tmp),
    error = function(e) {
      cli::cli_abort("Failed to download {.url {url}}.", parent = e)
    }
  )
  if (!is.null(checksum)) {
    actual <- .fresh_sha256(tmp)
    if (!identical(tolower(actual), tolower(checksum))) {
      cli::cli_abort(c(
        "Checksum mismatch for {.url {url}}.",
        i = "Expected {.val {checksum}}, got {.val {actual}}."
      ))
    }
  }
  .fresh_move(tmp, dest)
}

#' Build a setter that downloads and reads a file
#'
#' @param url_constructor `function` `function(key)` returning the URL for
#'   version `key`.
#' @param reader `function` `function(path)` returning the value. Defaults to
#'   [readRDS()].
#' @param checksum_finder `function` `function(key)` returning the expected
#'   sha256 of the downloaded file for version `key`, or `NULL` to skip
#'   verification.
#' @param digest_finder `function` `function(key)` returning the expected
#'   [fresh_digest()] of the value `reader` returns for version `key`, or
#'   `NULL` to skip verification.
#' @inheritParams safely_fetch
#' @returns `function` A `function(key)` suitable for `keep_fresh(setters = )`.
#' @keywords internal
construct_fetcher <- function(
  url_constructor,
  reader = readRDS,
  checksum_finder = NULL,
  digest_finder = NULL,
  downloader = fetch_binary
) {
  force(url_constructor)
  force(reader)
  force(checksum_finder)
  force(digest_finder)
  force(downloader)
  function(key) {
    # Resolve eagerly so errors from url_constructor() and the finders aren't
    # re-raised as interrupted promises inside safely_fetch().
    src <- url_constructor(key)
    expected <- if (!is.null(checksum_finder)) checksum_finder(key)
    digest <- if (!is.null(digest_finder)) digest_finder(key)
    tmp <- tempfile()
    on.exit(unlink(tmp))
    safely_fetch(src, tmp, checksum = expected, downloader = downloader)
    .fresh_verify_digest(reader(tmp), digest, src)
  }
}

#' Download a file in binary mode, erroring on failure
#'
#' A wrapper around [utils::download.file()] with `mode = "wb"` and
#' `quiet = TRUE` that errors on a non-zero status instead of returning it.
#'
#' @param url `character(1)` URL to download.
#' @param dest `character(1)` Destination path.
#' @returns `dest`, invisibly.
#' @keywords internal
fetch_binary <- function(url, dest) {
  # nocov start
  status <- utils::download.file(url, dest, mode = "wb", quiet = TRUE)
  if (status != 0) {
    cli::cli_abort("{.fn utils::download.file} returned status {status}.")
  }
  invisible(dest)
  # nocov end
}
