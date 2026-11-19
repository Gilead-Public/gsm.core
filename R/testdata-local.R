# Local test data builds (#219) ------------------------------------------------
#
# With the `gsm.testdata_builder` option set, gsm.core builds test data from
# local packages into `<.testdata_dir()>/local/<inputs_hash>/`.
# `local/index.json` maps each build's data fingerprint to its folder, so a
# release with the same fingerprint is copied from the build instead of
# downloaded. A local build is served under the tag its fingerprint would
# have as a release (`data-<fp12>`), so cached values are keyed by
# fingerprint either way.

#' Rebuild local test data
#'
#' `r lifecycle::badge("experimental")`
#'
#' When gsm packages are loaded with `devtools::load_all()` or installed
#' locally (no `RemoteSha`), and no published gsm.datasim build matches them
#' exactly, gsm.core builds test data from them with the function in the
#' `gsm.testdata_builder` option: a function, or a `"pkg::fn"` string that is
#' resolved only when a build is needed. For example, in `.Rprofile`:
#'
#' ```r
#' options(gsm.testdata_builder = "gsm.datasim::build_testdata_bundle")
#' ```
#'
#' The builder is called as `builder(output_dir, overwrite = TRUE,
#' allow_local = TRUE)` and must write a snapshot folder (see
#' [read_snapshot()]) to `output_dir`. Builds are kept under
#' `tools::R_user_dir("gsm", "cache")` and reused for the same package
#' versions. Because local packages have no `RemoteSha`, code changes don't
#' trigger a rebuild; call `rebuild_local_testdata()` after changing code.
#'
#' If a published release has the same data fingerprint as a local build,
#' its objects are copied from the build rather than downloaded.
#'
#' A tag or folder set with [use_testdata_tag()] or [use_testdata_snapshot()]
#' takes priority over local builds.
#'
#' @returns `character(1)` The build folder, invisibly.
#' @export
rebuild_local_testdata <- function() {
  builder <- .testdata_builder()
  if (is.null(builder)) {
    cli::cli_abort(
      "Set the {.code gsm.testdata_builder} option to build local test data."
    )
  }
  handle <- gsm$testdata_handle
  state <- if (is.null(handle)) state_memory() else handle$state
  packages <- state$get("lookup")$packages %||% .testdata_index()$packages
  installed <- .testdata_installed(packages)
  .testdata_use_local(state, packages, installed, builder, rebuild = TRUE)
  if (!is.null(handle)) {
    handle$refresh()
  }
  invisible(.testdata_local_dir(installed))
}

#' Resolve the `gsm.testdata_builder` option
#'
#' @returns `function` The builder, or `NULL` if the option is unset.
#' @keywords internal
.testdata_builder <- function() {
  builder <- getOption("gsm.testdata_builder")
  if (is.null(builder) || is.function(builder)) {
    return(builder)
  }
  parts <- if (rlang::is_string(builder)) {
    strsplit(builder, "::", fixed = TRUE)[[1]]
  }
  if (length(parts) != 2 || !all(nzchar(parts))) {
    cli::cli_abort(
      "The {.code gsm.testdata_builder} option must be a function or a
       {.val pkg::fn} string."
    )
  }
  fn <- tryCatch(
    getExportedValue(parts[[1]], parts[[2]]),
    error = function(e) {
      cli::cli_abort(
        "Can't find the test data builder {.code {builder}}.",
        parent = e
      )
    }
  )
  if (!is.function(fn)) {
    cli::cli_abort("The test data builder {.code {builder}} isn't a function.")
  }
  fn
}

#' Is any indexed package installed or loaded without a `RemoteSha`?
#'
#' @param installed `list` Output of [package_versions()].
#' @returns `logical(1)`
#' @keywords internal
.testdata_has_local_pkg <- function(installed) {
  any(vapply(
    installed,
    function(p) !is.na(p$version %||% NA) && is.na(p$remote_sha %||% NA),
    logical(1)
  ))
}

#' Folder for local builds
#'
#' @returns `character(1)` The root for all local builds.
#' @keywords internal
.testdata_local_root <- function() {
  file.path(.testdata_dir(), "local")
}

#' Folder for one local build
#'
#' @param installed `list` Output of [package_versions()].
#' @returns `character(1)` The build folder for `installed`.
#' @keywords internal
.testdata_local_dir <- function(installed) {
  file.path(.testdata_local_root(), fresh_inputs_hash(installed))
}

#' Are we inside R CMD INSTALL or R CMD check?
#'
#' Messages in these processes show up as check WARNINGs or NOTEs, so
#' informational messages are skipped there.
#'
#' @returns `logical(1)`
#' @keywords internal
.testdata_quiet_context <- function() {
  nzchar(Sys.getenv("_R_CHECK_PACKAGE_NAME_")) ||
    nzchar(Sys.getenv("R_INSTALL_PKG"))
}

#' Find a local build matching the installed packages
#'
#' Scans `root` for builds whose folder name is the `fresh_inputs_hash()` of
#' the packages listed in their own snapshot, as installed now. Works without
#' the test data index (e.g. offline, or before the cache is redirected).
#'
#' @param root `character(1)` Folder holding local builds.
#' @returns `character(1)` The matching build folder, or `NULL`.
#' @keywords internal
.testdata_local_match <- function(root = .testdata_local_root()) {
  for (dir in list.dirs(root, recursive = FALSE)) {
    if (!.testdata_local_exists(dir)) {
      next
    }
    packages <- names(
      tryCatch(read_snapshot(dir)$packages, error = function(e) NULL)
    )
    if (
      length(packages) &&
        identical(
          fresh_inputs_hash(.testdata_installed(packages)),
          basename(dir)
        )
    ) {
      return(dir)
    }
  }
  NULL
}

#' Does a folder hold a readable local build?
#'
#' @param dir `character(1)` or `NULL`.
#' @returns `logical(1)` `TRUE` if `dir` has a valid `snapshot.json`, so a
#'   damaged build can't take priority over usable published data.
#' @keywords internal
.testdata_local_exists <- function(dir) {
  rlang::is_string(dir) &&
    file.exists(file.path(dir, "snapshot.json")) &&
    !is.null(tryCatch(read_snapshot(dir), error = function(e) NULL))
}

#' Use (building if needed) the local build for the installed packages
#'
#' @param state `FreshState` The checker's state store.
#' @param packages `character` The indexed package names.
#' @param installed `list` Output of [package_versions()] for `packages`.
#' @param builder `function` From [.testdata_builder()].
#' @param rebuild `logical(1)` Build even if a build exists?
#' @returns `character(1)` The tag to use (`data-<fp12>`).
#' @keywords internal
.testdata_use_local <- function(
  state,
  packages,
  installed,
  builder = .testdata_builder(),
  rebuild = FALSE
) {
  dir <- .testdata_local_dir(installed)
  if (rebuild || !.testdata_local_exists(dir)) {
    .testdata_local_build(dir, builder, rebuild)
  } else if (
    !isTRUE(getOption("gsm.testdata_local_informed")) &&
      !.testdata_quiet_context()
  ) {
    cli::cli_inform(c(
      "Using local gsm test data from {.path {dir}}.",
      i = "After changing code, rebuild with
           {.run gsm.core::rebuild_local_testdata()}."
    ))
  }
  # The checker can run many times a session, and devtools::load_all() resets
  # package state, so use an option to remember that the user has been told.
  options(gsm.testdata_local_informed = TRUE)
  snapshot <- read_snapshot(dir)
  fingerprint <- .testdata_local_fingerprint(snapshot)
  .testdata_local_register(fingerprint, basename(dir))
  tag <- paste0("data-", substr(fingerprint, 1, 12))
  snapshot$key <- paste0("sha256:", fingerprint)
  # A rebuild can change the folder's data, so forget snapshots memoized for
  # it under other tags; they'd fail digest checks instead of downloading.
  stale <- vapply(
    gsm$testdata_snapshots %||% list(),
    function(s) identical(s$dir, snapshot$dir),
    logical(1)
  )
  gsm$testdata_snapshots[names(stale)[stale]] <- NULL
  gsm$testdata_snapshots[[tag]] <- snapshot
  state$set(
    "lookup",
    list(
      packages = packages,
      installed = installed,
      tag = tag,
      fingerprint = fingerprint,
      match = "local",
      dir = dir
    )
  )
  tag
}

#' Run the builder into a local build folder
#'
#' Builds into a temporary sibling folder, then replaces `dir`, so a failed
#' build leaves any previous one intact. Concurrent sessions don't lock each
#' other out: if another session finishes the same automatic build first, its
#' result is kept, and the swap never leaves `dir` missing while it's in use.
#'
#' @param dir `character(1)` The build folder.
#' @inheritParams .testdata_use_local
#' @returns `dir`, invisibly.
#' @keywords internal
.testdata_local_build <- function(dir, builder, rebuild = FALSE) {
  cli::cli_inform("Building local gsm test data in {.path {dir}} ...")
  fs::dir_create(dirname(dir))
  tmp <- tempfile("build-", tmpdir = dirname(dir))
  on.exit(unlink(tmp, recursive = TRUE))
  tryCatch(
    {
      fs::dir_create(tmp)
      builder(tmp, overwrite = TRUE, allow_local = TRUE)
      read_snapshot(tmp)
    },
    error = function(e) {
      cli::cli_abort("Failed to build local gsm test data.", parent = e)
    }
  )
  # Another session may have finished the same build meanwhile; for an
  # automatic build, keep theirs. Swap folders by renaming, so a reader never
  # sees `dir` deleted before its replacement is in place.
  if (!rebuild && .testdata_local_exists(dir)) {
    return(invisible(dir))
  }
  old <- tempfile("old-", tmpdir = dirname(dir))
  on.exit(unlink(old, recursive = TRUE), add = TRUE)
  if (dir.exists(dir)) {
    file.rename(dir, old)
  }
  if (!file.rename(tmp, dir) && !.testdata_local_exists(dir)) {
    cli::cli_abort("Can't move the local test data build to {.path {dir}}.") # nocov
  }
  invisible(dir)
}

#' Data fingerprint of a snapshot
#'
#' @param snapshot `list` Output of [read_snapshot()].
#' @returns `character(1)` [fresh_fingerprint()] of its object digests, the
#'   same way release fingerprints are computed.
#' @keywords internal
.testdata_local_fingerprint <- function(snapshot) {
  fresh_fingerprint(lapply(snapshot$objects, function(o) tolower(o$digest)))
}

#' Read the local build index
#'
#' @returns `list` Fingerprint -> build folder name. Empty if missing or
#'   unreadable.
#' @keywords internal
.testdata_local_index <- function() {
  path <- file.path(.testdata_local_root(), "index.json")
  if (!file.exists(path)) {
    return(list())
  }
  tryCatch(as.list(jsonlite::read_json(path)), error = function(e) list())
}

#' Record a local build in the local index
#'
#' @param fingerprint `character(1)` The build's data fingerprint.
#' @param name `character(1)` The build folder name (its inputs hash).
#' @returns `list` The index, invisibly.
#' @keywords internal
.testdata_local_register <- function(fingerprint, name) {
  index <- .testdata_local_index()
  # A rebuild replaces the folder's previous fingerprint.
  index <- index[!vapply(index, identical, logical(1), name)]
  index[[fingerprint]] <- name
  .fresh_write_json(index, file.path(.testdata_local_root(), "index.json"))
  invisible(index)
}

#' Find a local build for a release tag
#'
#' @inheritParams .testdata_url
#' @returns `list` Output of [read_snapshot()] with `key` set to the
#'   release's, or `NULL` if no valid local build has that fingerprint.
#' @keywords internal
.testdata_local_find <- function(tag) {
  if (!grepl("^data-[0-9a-f]{12}$", tag)) {
    return(NULL)
  }
  index <- .testdata_local_index()
  hits <- index[startsWith(
    names(index) %||% character(),
    sub("^data-", "", tag)
  )]
  for (fingerprint in names(hits)) {
    snapshot <- tryCatch(
      read_snapshot(file.path(.testdata_local_root(), hits[[fingerprint]])),
      error = function(e) NULL
    )
    # The folder may have been rebuilt or edited since it was indexed.
    if (
      !is.null(snapshot) &&
        identical(.testdata_local_fingerprint(snapshot), fingerprint)
    ) {
      snapshot$key <- paste0("sha256:", fingerprint)
      return(snapshot)
    }
  }
  NULL
}
