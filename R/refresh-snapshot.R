# refresh: snapshots and package-version tracking ----------------------------
#
# Part of the would-be "refresh" package; no gsm-specific code here.
#
# A snapshot is a "hard copy" of a set of fresh values: a folder of RDS files
# plus snapshot.json describing them. While a handle uses a snapshot, values
# come from the folder; the checker, setters, and cache are bypassed.
#
# snapshot.json (format version 2):
# {
#   "refresh_snapshot": 2,                 // format version (required)
#   "key": "testdata-dev-20261030T182506Z", // version key (string; required)
#   "created": "2026-10-30T18:25:06Z",
#   "objects": {                           // required
#     "<binding name>": {"file": "<path relative to dir>", "digest": "<hex>"}
#   },
#   "packages": {                          // optional
#     "<pkg>": {"version": "1.2.3", "remote_sha": "<sha or null>"}
#   },
#   "metadata": {}                         // optional; free-form, for the producer
# }
#
# Each object is an RDS file, and `digest` is fresh_digest() of the R object it
# holds, not a hash of the file, so it doesn't depend on the R version or
# compression that wrote the file. Format 1 (file sha256) is no longer read.

.snapshot_format <- 2L

#' Read a snapshot's description
#'
#' `r lifecycle::badge("experimental")`
#'
#' Reads and validates `snapshot.json` in a snapshot folder, such as one
#' written by [write_snapshot_json()]. Part of gsm.core's "refresh" tools,
#' exported for other gsm packages (e.g. gsm.datasim).
#'
#' @param dir `character(1)` Snapshot folder containing `snapshot.json`.
#' @returns `list` The parsed `snapshot.json`, with `dir` (normalized) added.
#' @family refresh
#' @export
read_snapshot <- function(dir) {
  if (!dir.exists(dir)) {
    cli::cli_abort("Snapshot folder {.path {dir}} does not exist.")
  }
  path <- file.path(dir, "snapshot.json")
  if (!file.exists(path)) {
    cli::cli_abort("No {.file snapshot.json} in {.path {dir}}.")
  }
  info <- parse_snapshot(jsonlite::read_json(path), source = path)
  info$dir <- normalizePath(dir, winslash = "/")
  info
}

#' Validate a parsed snapshot.json
#'
#' @param info `list` `snapshot.json` parsed with [jsonlite::read_json()].
#' @param source `character(1)` Where it came from, for error messages.
#' @returns `list` `info`, unchanged.
#' @keywords internal
parse_snapshot <- function(info, source = "snapshot.json") {
  format <- info$refresh_snapshot
  if (is.null(format) || !is.numeric(format)) {
    cli::cli_abort("{.file {source}} has no {.field refresh_snapshot} version.")
  }
  if (format > .snapshot_format) {
    cli::cli_abort(c(
      "{.file {source}} uses snapshot format {format}.",
      i = "It needs a newer version of refresh (this one reads format {(.snapshot_format)})."
    ))
  }
  if (format < .snapshot_format) {
    cli::cli_abort(c(
      "{.file {source}} uses snapshot format {format}, which is no longer
       supported.",
      i = "Rebuild it with this version of refresh (format
           {(.snapshot_format)})."
    ))
  }
  if (!rlang::is_string(info$key) || !is.list(info$objects)) {
    cli::cli_abort(
      "{.file {source}} needs a string {.field key} and {.field objects}."
    )
  }
  info
}

#' Compute a file's sha256, treating CRLF as LF in text files
#'
#' Text files (no NUL bytes, the same heuristic Git uses) are hashed with CRLF
#' normalized to LF, so a copy whose line endings were converted (e.g. by a
#' Windows checkout or download tool) still verifies. Other files are hashed
#' byte for byte. For LF text and binary files this equals the plain file
#' sha256 (#215).
#'
#' @param path `character(1)` Path to the file.
#' @returns `character(1)` The lowercase hex sha256.
#' @keywords internal
.fresh_sha256 <- function(path) {
  bytes <- readBin(path, "raw", file.size(path))
  if (!any(bytes == as.raw(0))) {
    cr <- which(bytes == as.raw(0x0d))
    crlf <- cr[cr < length(bytes) & bytes[cr + 1L] == as.raw(0x0a)]
    if (length(crlf)) {
      bytes <- bytes[-crlf]
    }
  }
  digest::digest(bytes, algo = "sha256", serialize = FALSE)
}

#' Digest an R object
#'
#' `r lifecycle::badge("experimental")`
#'
#' The SHA-256 of an R object's serialization (format version 2, skipping R's
#' serialization header), as recorded for snapshot objects and combined by
#' [fresh_fingerprint()]. It digests the object rather than a file, so the
#' same object saved by different R versions or with different compression
#' has the same digest.
#'
#' Objects that are [identical()] can still digest differently if their
#' strings use different encodings (e.g. UTF-8 vs latin1) or their attributes
#' were set in a different order. A deterministic build doesn't do that.
#'
#' @param x Any R object.
#' @returns `character(1)` A 64-character lowercase hex string.
#' @examples
#' fresh_digest(mtcars)
#' @family refresh
#' @export
fresh_digest <- function(x) {
  digest::digest(x, algo = "sha256", serializeVersion = 2L)
}

#' Fingerprint a set of object digests
#'
#' `r lifecycle::badge("experimental")`
#'
#' Combines named object digests (from [fresh_digest()]) into one fingerprint:
#' the SHA-256 of one `"<name>:<digest>"` line per object, sorted by name in
#' C-locale order and joined with `"\n"`. Neither the order of `digests` nor
#' the locale affects the result.
#'
#' @param digests `character` or `list` Named; object name -> digest. Names
#'   must be unique and non-empty.
#' @returns `character(1)` A 64-character lowercase hex string.
#' @examples
#' digests <- lapply(list(cars = mtcars, flowers = iris), fresh_digest)
#' fresh_fingerprint(digests)
#' @family refresh
#' @export
fresh_fingerprint <- function(digests) {
  ok <- length(digests) > 0 &&
    rlang::is_named(digests) &&
    !anyDuplicated(names(digests)) &&
    all(vapply(digests, rlang::is_string, logical(1)))
  if (!ok) {
    cli::cli_abort(
      "{.arg digests} must be single strings with unique, non-empty names."
    )
  }
  digests <- unlist(digests)[order(names(digests), method = "radix")]
  digest::digest(
    enc2utf8(paste0(names(digests), ":", digests, collapse = "\n")),
    algo = "sha256",
    serialize = FALSE
  )
}

#' Write snapshot.json for files already in a folder
#'
#' `r lifecycle::badge("experimental")`
#'
#' Describes RDS files already in a snapshot folder, reading each one to
#' record its object's [fresh_digest()]. Part of gsm.core's "refresh" tools,
#' exported for other gsm packages (e.g. gsm.datasim).
#'
#' @param dir `character(1)` Snapshot folder containing the files.
#' @param objects `character` or `list` Named; object name -> RDS file name
#'   (relative to `dir`).
#' @param key `character(1)` Version key.
#' @param packages `list` Optional output of [package_versions()].
#' @param metadata `list` Optional named list, stored as-is.
#' @returns `list` The snapshot description, invisibly.
#' @examples
#' dir <- file.path(tempdir(), "snapshot-example")
#' dir.create(dir)
#' saveRDS(mtcars, file.path(dir, "cars.rds"))
#' digests <- list(cars = fresh_digest(mtcars))
#' write_snapshot_json(
#'   dir,
#'   objects = c(cars = "cars.rds"),
#'   key = paste0("sha256:", fresh_fingerprint(digests))
#' )
#' read_snapshot(dir)$objects
#' unlink(dir, recursive = TRUE)
#' @family refresh
#' @export
write_snapshot_json <- function(
  dir,
  objects,
  key,
  packages = NULL,
  metadata = NULL
) {
  stopifnot(rlang::is_named(objects), rlang::is_string(key))
  objects <- lapply(as.list(objects), function(file) {
    path <- file.path(dir, file)
    if (!file.exists(path)) {
      cli::cli_abort("{.path {path}} does not exist.")
    }
    list(file = file, digest = fresh_digest(readRDS(path)))
  })
  info <- list(
    refresh_snapshot = .snapshot_format,
    key = key,
    created = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),
    objects = objects
  )
  if (length(packages)) {
    info$packages <- lapply(packages, function(p) {
      sha <- p$remote_sha
      list(
        version = p$version,
        remote_sha = if (is.null(sha) || is.na(sha)) NULL else sha
      )
    })
  }
  if (length(metadata)) {
    info$metadata <- metadata
  }
  .fresh_write_json(info, file.path(dir, "snapshot.json"))
  invisible(info)
}

#' Read and verify one object from a snapshot
#'
#' @param snapshot `list` Output of [read_snapshot()].
#' @param name `character(1)` Object name in `snapshot$objects`.
#' @returns The object read from its RDS file, verified against its digest.
#' @keywords internal
.snapshot_read_object <- function(snapshot, name) {
  entry <- snapshot$objects[[name]]
  if (is.null(entry)) {
    cli::cli_abort(
      "{.val {name}} is not in the snapshot at {.path {snapshot$dir}}."
    )
  }
  path <- file.path(snapshot$dir, entry$file)
  if (!file.exists(path)) {
    cli::cli_abort("Snapshot file {.path {path}} is missing.")
  }
  .fresh_verify_digest(readRDS(path), entry$digest, path)
}

#' Check an object against its expected digest
#'
#' @param x The object, e.g. just read from `source`.
#' @param expected `character(1)` Expected [fresh_digest()], or `NULL` to skip
#'   verification.
#' @param source `character(1)` Where `x` came from, for error messages.
#' @returns `x`, if it matches. Errors otherwise.
#' @keywords internal
.fresh_verify_digest <- function(x, expected, source) {
  if (is.null(expected)) {
    return(x)
  }
  actual <- fresh_digest(x)
  if (!identical(actual, tolower(expected))) {
    cli::cli_abort(c(
      "Digest mismatch for {.path {source}}.",
      i = "Expected {.val {expected}}, got {.val {actual}}."
    ))
  }
  x
}

#' Tell the user if installed packages are newer than a snapshot's
#'
#' @inheritParams .snapshot_read_object
#' @returns `character` Names of newer packages, invisibly.
#' @keywords internal
.snapshot_check_packages <- function(snapshot) {
  recorded <- snapshot$packages
  if (!length(recorded)) {
    return(invisible())
  }
  newer <- .fresh_packages_newer(package_versions(names(recorded)), recorded)
  if (length(newer)) {
    cli::cli_inform(c(
      "Installed {.pkg {newer}} {cli::qty(newer)}{?is/are} newer than the
       snapshot at {.path {snapshot$dir}}.",
      i = "Using the snapshot anyway."
    ))
  }
  invisible(newer)
}

# Package versions ------------------------------------------------------------

#' Installed versions of packages
#'
#' `r lifecycle::badge("experimental")`
#'
#' Records the version and `RemoteSha` (set when installed from GitHub, e.g.
#' with pak or remotes) of each package. Pass the result to
#' `write_snapshot_json(packages = )` to record which package versions built a
#' snapshot, or call it from a [keep_fresh()] checker and store the result in
#' its `state` to decide whether the data needs checking again (e.g. skip a
#' remote lookup until installed packages change).
#'
#' @param packages `character` Package names.
#' @returns `list` Named by package; each element has `version` and
#'   `remote_sha` (both `NA` when unknown or not installed).
#' @examples
#' package_versions(c("gsm.core", "not.a.package"))
#' @family refresh
#' @export
package_versions <- function(packages) {
  lapply(rlang::set_names(unique(packages)), function(pkg) {
    desc <- suppressWarnings(
      utils::packageDescription(pkg, fields = c("Version", "RemoteSha"))
    )
    if (!is.list(desc)) {
      return(list(version = NA_character_, remote_sha = NA_character_))
    }
    list(
      version = desc$Version %||% NA_character_,
      remote_sha = desc$RemoteSha %||% NA_character_
    )
  })
}

#' Hash the package versions that built something
#'
#' `r lifecycle::badge("experimental")`
#'
#' The SHA-256 of one `"<package> <version> <remote_sha>"` line per package
#' (a missing SHA as `NA`), sorted by name in C-locale order and joined with
#' `"\n"`. gsm.datasim records it as each test data build's `inputs_hash`,
#' and gsm.core uses it to find the build that matches the installed
#' packages.
#'
#' @param packages `list` Named by package; each element has `version` and
#'   `remote_sha`, as from [package_versions()].
#' @returns `character(1)` A 64-character lowercase hex string.
#' @examples
#' fresh_inputs_hash(package_versions("gsm.core"))
#' @family refresh
#' @export
fresh_inputs_hash <- function(packages) {
  pkgs <- names(packages)[order(names(packages), method = "radix")]
  lines <- vapply(
    pkgs,
    function(pkg) {
      p <- packages[[pkg]]
      sha <- p$remote_sha
      if (is.null(sha) || is.na(sha)) {
        sha <- "NA"
      }
      paste(pkg, p$version, sha)
    },
    character(1),
    USE.NAMES = FALSE
  )
  digest::digest(
    enc2utf8(paste(lines, collapse = "\n")),
    algo = "sha256",
    serialize = FALSE
  )
}

#' Which installed packages are newer than recorded versions?
#'
#' @param installed `list` Output of [package_versions()].
#' @param recorded `list` The same shape, e.g. from a snapshot. `remote_sha`
#'   may be absent.
#' @returns `character` Names of packages with a higher version, or the same
#'   version but a different `remote_sha`. Packages that aren't installed or
#'   recorded are ignored.
#' @keywords internal
.fresh_packages_newer <- function(installed, recorded) {
  is_newer <- vapply(
    names(installed),
    function(pkg) {
      inst <- installed[[pkg]]
      ref <- recorded[[pkg]]
      if (is.na(inst$version %||% NA) || is.null(ref$version)) {
        return(FALSE)
      }
      cmp <- utils::compareVersion(inst$version, ref$version)
      if (cmp != 0) {
        return(cmp > 0)
      }
      inst_sha <- inst$remote_sha %||% NA
      ref_sha <- ref$remote_sha %||% NA
      !is.na(inst_sha) && !is.na(ref_sha) && !identical(inst_sha, ref_sha)
    },
    logical(1)
  )
  names(installed)[is_newer]
}

#' Have these packages changed since the checker last looked?
#'
#' @param state `FreshState` The checker's state store (see [state_file()]).
#'   The installed versions are saved in it.
#' @inheritParams package_versions
#' @param slot `character(1)` State entry to use, so one checker can track
#'   several sets.
#' @returns `logical(1)` `TRUE` if anything changed (or on first use), else
#'   `FALSE`.
#' @keywords internal
.fresh_packages_changed <- function(state, packages, slot = "packages") {
  installed <- package_versions(sort(unique(packages)))
  changed <- !identical(installed, state$get(slot))
  if (changed) {
    state$set(slot, installed)
  }
  changed
}

# FreshHandle method bodies --------------------------------------------------
#
# FreshHandle (R/refresh.R) delegates to these so the snapshot logic lives here.

#' Write a snapshot of a handle's values
#'
#' Body of `FreshHandle$save_snapshot()`.
#'
#' @param self,private `R6` The handle's `self` and `private`.
#' @param dir `character(1)` Snapshot folder to write. Created if needed.
#' @param names `character` Binding names to save. `NULL` saves all.
#' @param packages `character` Package names whose installed versions are
#'   recorded, or `NULL`.
#' @param key `character(1)` Version key. `NULL` uses the handle's current
#'   key.
#' @inheritParams write_snapshot_json
#' @returns `list` The snapshot description, invisibly.
#' @keywords internal
.fresh_save_snapshot <- function(
  self,
  private,
  dir,
  names,
  packages,
  key,
  metadata
) {
  all <- private$names
  names <- names %||% all
  unknown <- setdiff(names, all)
  if (length(unknown)) {
    cli::cli_abort("Unknown object{?s}: {.val {unknown}}.")
  }
  if (is.null(private$snapshot_)) {
    # Check once, then hold the key so every object comes from one version.
    private$current_key()
    old_check <- private$check
    private$check <- "session"
    on.exit(private$check <- old_check, add = TRUE)
  }
  values <- lapply(rlang::set_names(names), private$value_for)
  key <- key %||% private$snapshot_$key %||% private$key_
  if (!rlang::is_string(key)) {
    cli::cli_abort(c(
      "The current version key isn't a single string.",
      i = "Supply {.arg key} to label the snapshot."
    ))
  }
  dir.create(dir, recursive = TRUE, showWarnings = FALSE)
  objects <- unname(private$snapshot_names[names])
  files <- rlang::set_names(paste0(objects, ".rds"), objects)
  for (i in seq_along(names)) {
    .fresh_write_rds(values[[names[[i]]]], file.path(dir, files[[i]]))
  }
  write_snapshot_json(
    dir,
    objects = files,
    key = key,
    packages = if (length(packages)) package_versions(packages),
    metadata = metadata
  )
}

#' Read a handle's values from a snapshot
#'
#' Body of `FreshHandle$use_snapshot()`.
#'
#' @inheritParams .fresh_save_snapshot
#' @param dir `character(1)` Snapshot folder to read, or `NULL` to stop using
#'   one.
#' @param check_packages `logical(1)` Tell the user if installed packages are
#'   newer than the snapshot's?
#' @returns `FreshHandle` The handle, invisibly.
#' @keywords internal
.fresh_use_snapshot <- function(self, private, dir, check_packages) {
  snapshot <- if (!is.null(dir)) read_snapshot(dir)
  if (!is.null(snapshot) && isTRUE(check_packages)) {
    .snapshot_check_packages(snapshot)
  }
  private$snapshot_ <- snapshot
  private$key_ <- snapshot$key
  private$checked_at <- NULL
  private$values <- new.env(parent = emptyenv())
  invisible(self)
}
