# refresh: download helpers --------------------------------------------------
#
# Part of the would-be "refresh" package; no gsm-specific code here.

#' Download a file, optionally verifying a sha256 checksum
#'
#' @param url URL to download.
#' @param dest Destination path. Written atomically.
#' @param checksum Expected sha256 (hex) or `NULL` to skip verification.
#' @param request `function(url, dest)` that performs the download. Override
#'   for authentication, APIs, etc. Defaults to [utils::download.file()].
#' @noRd
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
    actual <- unname(tools::sha256sum(tmp))
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
#' @param url `function(key)` returning the URL for version `key`.
#' @param read `function(path)` returning the value. Defaults to [readRDS()].
#' @param checksum `function(key)` returning the expected sha256, or `NULL`.
#' @param request Passed to `fetch_file()`.
#' @returns A `function(key)` suitable for `keep_fresh(setters = )`.
#' @noRd
download_setter <- function(url, read = readRDS, checksum = NULL, request = NULL) {
  force(url)
  force(read)
  force(checksum)
  force(request)
  function(key) {
    tmp <- tempfile()
    on.exit(unlink(tmp))
    fetch_file(
      url(key),
      tmp,
      checksum = if (!is.null(checksum)) checksum(key),
      request = request
    )
    read(tmp)
  }
}

.fresh_default_request <- function(url, dest) {
  status <- utils::download.file(url, dest, mode = "wb", quiet = TRUE)
  if (status != 0) {
    stop("download.file() returned status ", status, call. = FALSE)
  }
  invisible(dest)
}
