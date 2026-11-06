# refresh: download helpers --------------------------------------------------
#
# Part of the would-be "refresh" package; no gsm-specific code here.

#' Download a file, optionally verifying a sha256 checksum
#'
#' @param url `character(1)` URL to download.
#' @param dest `character(1)` Destination path. Written atomically.
#' @param checksum `character(1)` Expected sha256 (hex), or `NULL` to skip
#'   verification.
#' @param request `function` `function(url, dest)` that performs the download.
#'   Override for authentication, APIs, etc. `NULL` uses
#'   [.fresh_default_request()].
#' @returns `dest`, invisibly.
#' @keywords internal
fetch_file <- function(url, dest, checksum = NULL, request = NULL) {
  request <- request %||% .fresh_default_request
  dir.create(dirname(dest), recursive = TRUE, showWarnings = FALSE)
  tmp <- tempfile(tmpdir = dirname(dest), fileext = ".tmp")
  on.exit(unlink(tmp))

  tryCatch(
    request(url, tmp),
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
#' @param url `function` `function(key)` returning the URL for version `key`.
#' @param read `function` `function(path)` returning the value. Defaults to
#'   [readRDS()].
#' @param checksum `function` `function(key)` returning the expected sha256,
#'   or `NULL` to skip verification.
#' @inheritParams fetch_file
#' @returns `function` A `function(key)` suitable for `keep_fresh(setters = )`.
#' @keywords internal
download_setter <- function(
  url,
  read = readRDS,
  checksum = NULL,
  request = NULL
) {
  force(url)
  force(read)
  force(checksum)
  force(request)
  function(key) {
    # Resolve eagerly so errors from url()/checksum() aren't re-raised as
    # interrupted promises inside fetch_file().
    src <- url(key)
    expected <- if (!is.null(checksum)) checksum(key)
    tmp <- tempfile()
    on.exit(unlink(tmp))
    fetch_file(src, tmp, checksum = expected, request = request)
    read(tmp)
  }
}

#' Download a file with download.file()
#'
#' @inheritParams fetch_file
#' @returns `dest`, invisibly. Errors on a non-zero status.
#' @keywords internal
.fresh_default_request <- function(url, dest) {
  status <- utils::download.file(url, dest, mode = "wb", quiet = TRUE)
  if (status != 0) {
    stop("download.file() returned status ", status, call. = FALSE)
  }
  invisible(dest)
}
