# gsm.datasim test data served via keep_fresh() (see R/refresh*.R) -----------
#
# Data lives in gsm.datasim releases tagged `data-<fp12>`, one per data
# fingerprint. Each has snapshot.json plus one asset per snapshot object.
# The gsm.datasim `data-index` branch's index.json maps the package versions
# that built each bundle to its fingerprint and release. See #206 and
# Gilead-Public/gsm.datasim#153.
#
# Settings live in `gsm` environment (created in R/gsm.core-package.R) See
# `use_testdata_snapshot()` etc. Their defaults read GSM_TESTDATA_SNAPSHOT /
# GSM_TESTDATA_TAG; .onLoad calls them.

# Tell NAMESPACE about the objects.

#' @evalNamespace fresh_exports(names(.testdata_objects))
NULL

# reusable config objects ----

# Binding name -> object name in the release's snapshot.json.
.testdata_objects <- rlang::set_names(c(
  "lSource",
  "analyticsInput",
  "analyticsSummary",
  "reportingResults",
  "reportingGroups",
  "reportingBounds",
  "reportingMetrics",
  "reportingResults_country",
  "reportingGroups_country",
  "reportingBounds_country",
  "reportingMetrics_country",
  "reportingResults_study",
  "reportingGroups_study",
  "reportingBounds_study",
  "reportingMetrics_study"
))

.testdata_repo <- "Gilead-Public/gsm.datasim"

.testdata_index_url <- paste0(
  "https://raw.githubusercontent.com/",
  .testdata_repo,
  "/refs/heads/data-index/index.json"
)

.testdata_index_format <- 2L

#' Matching reporting inputs for the bundled ActionLog
#'
#' Loads the reporting results, groups, metrics and bounds from the immutable
#' test data release used to generate [reportingActionLog]. Uses the normal
#' test data cache, or a matching local snapshot, without changing the release
#' selected for other test data objects.
#'
#' @returns A named list containing `reportingResults`, `reportingGroups`,
#'   `reportingMetrics` and `reportingBounds`.
#' @export
action_log_testdata <- function() {
  tag <- "data-8cde53949d4d"
  objects <- c("reportingResults", "reportingGroups", "reportingMetrics", "reportingBounds")
  setters <- lapply(objects, function(object) {
    force(object)
    construct_fetcher(
      url_constructor = function(key) {
        .testdata_url(key, .testdata_object_entry(key, object)$file)
      },
      checksum_finder = function(key) .testdata_object_entry(key, object)$sha256
    )
  })
  names(setters) <- objects
  inputs <- new.env(parent = emptyenv())
  current <- gsm_testdata()
  handle <- keep_fresh(
    checker = function(state) tag,
    setters = setters,
    env = inputs,
    cache = current$cache
  )
  fingerprint <- "sha256:8cde53949d4d7e1dcf3741905dbf42303a35ca96e662ea129306016c3a55572d"
  if (!is.null(current$snapshot) && identical(current$snapshot$key, fingerprint)) {
    handle$use_snapshot(current$snapshot$dir)
  }
  mget(objects, envir = inputs, inherits = FALSE)
}

#' Folder for test data state and downloads
#'
#' @returns `character(1)` `tools::R_user_dir("gsm", "cache")`.
#' @keywords internal
.testdata_dir <- function() {
  tools::R_user_dir("gsm", "cache") # nocov
}

#' URL of a release asset
#'
#' @param tag `character(1)` Release tag, e.g. `"data-8cde53949d4d"`.
#' @param asset `character(1)` Asset file name.
#' @returns `character(1)` The download URL.
#' @keywords internal
.testdata_url <- function(tag, asset) {
  sprintf(
    "https://github.com/%s/releases/download/%s/%s",
    .testdata_repo,
    tag,
    asset
  )
}

# main entrypoint ----

#' Create the test data bindings and handle
#'
#' @param env `environment` Namespace to create the bindings in.
#' @param cache `cachem` Cache for downloaded values.
#' @returns `FreshHandle` The handle (also stored as `gsm$testdata_handle`),
#'   invisibly.
#' @keywords internal
.register_testdata <- function(
  env,
  cache = getOption("gsm.testdata_cache", .testdata_default_cache())
) {
  setters <- lapply(.testdata_objects, function(object) {
    construct_fetcher(
      url_constructor = function(tag) {
        .testdata_url(tag, .testdata_object_entry(tag, object)$file)
      },
      checksum_finder = function(tag) .testdata_object_entry(tag, object)$sha256
    )
  })
  gsm$testdata_handle <- keep_fresh(
    checker = .testdata_checker,
    setters = setters,
    env = env,
    cache = cache,
    state = state_file(function() {
      file.path(.testdata_dir(), "testdata-state.rds")
    }),
    snapshot_names = .testdata_objects
  )
  # Apply a folder set before the handle existed (e.g. GSM_TESTDATA_SNAPSHOT at
  # load). Never fail package loading over it.
  tryCatch(
    .testdata_apply_dir(),
    error = function(e) {
      cli::cli_warn(
        "Ignoring the test data folder set by {.fn use_testdata_snapshot}.",
        parent = e
      )
    }
  )
  invisible(gsm$testdata_handle)
}

#' Default test data cache
#'
#' @returns `cachem` A [cachem::cache_disk()] in `values/` under
#'   [.testdata_dir()].
#' @keywords internal
.testdata_default_cache <- function() {
  cachem::cache_disk(file.path(.testdata_dir(), "values"))
}

#' Inspect and manage the cached test data
#'
#' `r lifecycle::badge("experimental")`
#'
#' The test data objects (e.g. [analyticsInput]) are cached in a standard
#' \pkg{cachem} cache. `gsm_testdata()` returns a handle for inspecting and
#' managing the cache, and can be used to switch to a different cache.
#'
#' To change where or how values are cached, see [use_testdata_cache_dir()].
#'
#' @param cache `cachem` A \pkg{cachem} cache to use from now on. Defaults to
#'   the `gsm.testdata_cache` option; `NULL` keeps the current cache. A new
#'   cache is also stored in that option for the rest of the session. Objects
#'   already loaded this session stay in memory; later loads use the new
#'   cache.
#' @returns `FreshHandle` An R6 object with
#' * `key()`: the release tag currently in use.
#' * `refresh()`: choose the release again now.
#' * `reset()`: forget the release choice, so the next access re-resolves
#'   everything. Cached values are kept.
#' * `set_cache(cache)`: switch caches without changing the option.
#' * `cache`: the current cachem object. Use its methods directly, e.g.
#'   `gsm_testdata()$cache$size()`, `$keys()`, `$prune()`, `$reset()`
#'   (delete all cached values), or `$destroy()`.
#' * `state`: the store that records the chosen release; `state$path` shows
#'   where it's saved.
#' * `snapshot`: the local folder in use (see [use_testdata_snapshot()]), or
#'   `NULL`.
#' @examples
#' handle <- gsm_testdata()
#' handle
#' handle$cache$info()
#'
#' # Switch to a temporary in-memory cache, then back.
#' old <- handle$cache
#' gsm_testdata(cache = cachem::cache_mem())
#' gsm_testdata(cache = old)
#' @export
gsm_testdata <- function(cache = getOption("gsm.testdata_cache")) {
  handle <- gsm$testdata_handle
  if (!is.null(cache) && !identical(cache, handle$cache)) {
    handle$set_cache(cache)
    options(gsm.testdata_cache = cache)
  }
  handle
}

#' List test data object names
#'
#' `r lifecycle::badge("experimental")`
#'
#' Names of the test data objects (e.g. [lSource]) that gsm.core serves from
#' gsm.datasim test data releases.
#'
#' @returns `character` Object names.
#' @examples
#' testdata_object_names()
#' @export
testdata_object_names <- function() {
  names(.testdata_objects)
}

#' Check whether test data can be loaded
#'
#' `r lifecycle::badge("experimental")`
#'
#' Tries to load test data objects (e.g. [lSource]) and reports whether that
#' worked, without erroring. Objects are read from the snapshot folder set by
#' [use_testdata_snapshot()] or from the cache if possible, so this can return
#' `TRUE` offline. Otherwise they're downloaded, so the first call can be slow.
#' Useful for skipping examples, tests, or vignettes that need the data.
#'
#' @param objects `character` Names of the objects to check, from
#'   [testdata_object_names()]. Defaults to all of them.
#' @returns `logical(1)` `TRUE` if every object in `objects` loaded,
#'   otherwise `FALSE`.
#' @examples
#' testdata_is_available("lSource")
#' @export
testdata_is_available <- function(objects = testdata_object_names()) {
  unknown <- setdiff(objects, testdata_object_names())
  if (length(unknown)) {
    cli::cli_abort("Unknown test data object{?s}: {.val {unknown}}.")
  }
  ns <- asNamespace("gsm.core")
  tryCatch(
    {
      suppressMessages(
        for (name in objects) {
          get(name, envir = ns)
        }
      )
      TRUE
    },
    error = function(e) FALSE
  )
}

# Settings --------------------------------------------------------------------

#' Choose which test data gsm.core uses
#'
#' `r lifecycle::badge("experimental")`
#'
#' By default, gsm.core uses the gsm.datasim test data release built with the
#' gsm packages you have installed (see the "Release selection" section of
#' [lSource]). These functions override that choice:
#'
#' * `use_testdata_snapshot()`: read from a local snapshot folder containing
#'   `snapshot.json` and the files it lists, e.g. an unzipped
#'   `data-<id>.zip` release asset, for offline work or to test an
#'   unpublished bundle. Nothing is downloaded or cached. The folder is used
#'   even if installed packages are newer than the snapshot (with a message).
#'   Takes priority over `use_testdata_tag()`.
#' * `use_testdata_tag()`: use one exact gsm.datasim release, e.g.
#'   `"data-8cde53949d4d"`.
#'
#' Each function's default reads an environment variable
#' (`GSM_TESTDATA_SNAPSHOT`, `GSM_TESTDATA_TAG`). gsm.core calls both with
#' their defaults when it loads, so setting the variables (e.g. in `.Renviron`
#' or CI) applies them every session. Calling a function changes the setting
#' for the current session only.
#'
#' A folder is checked as soon as it's set (or, for `GSM_TESTDATA_SNAPSHOT`,
#' when gsm.core loads, with a warning instead of an error). A tag is checked
#' when the test data is next accessed.
#'
#' @param dir `character(1)` Path to a local snapshot folder. `NULL` or `""`
#'   stops using one.
#' @param tag `character(1)` A release tag. `NULL` or `""` stops pinning one.
#' @returns `character(1)` The previous value (or `NULL`), invisibly, so it
#'   can be restored later.
#' @examples
#' old <- use_testdata_tag("data-8cde53949d4d")
#' use_testdata_tag(old)
#'
#' # Re-read the environment variable:
#' use_testdata_tag()
#'
#' # Temporarily, e.g. in a test:
#' # withr::defer(use_testdata_tag(use_testdata_tag("data-...")))
#' @export
use_testdata_snapshot <- function(dir = Sys.getenv("GSM_TESTDATA_SNAPSHOT")) {
  old <- gsm$testdata_dir
  assign("testdata_dir", dir, envir = gsm)
  tryCatch(.testdata_apply_dir(), error = function(e) {
    assign("testdata_dir", old, envir = gsm)
    rlang::cnd_signal(e)
  })
  invisible(old)
}

#' @rdname use_testdata_snapshot
#' @export
use_testdata_tag <- function(tag = Sys.getenv("GSM_TESTDATA_TAG")) {
  old <- gsm$testdata_tag
  assign("testdata_tag", tag, envir = gsm)
  if (!is.null(gsm$testdata_handle)) {
    gsm$testdata_handle$invalidate()
  }
  invisible(old)
}

#' Choose where the test data is cached
#'
#' `r lifecycle::badge("experimental")`
#'
#' The test data objects (e.g. [lSource]) are cached in a \pkg{cachem} cache
#' after they're first downloaded. `use_testdata_cache_dir()` caches them on
#' disk in `dir`, by setting the `gsm.testdata_cache` option to
#' `cachem::cache_disk(dir)` and switching the current session to it.
#'
#' If the option is unset, gsm.core uses `cachem::cache_disk()` in
#' `tools::R_user_dir("gsm", "cache")` (set `R_USER_CACHE_DIR` to move it),
#' with cachem's default size limit and no age limit.
#'
#' Any cachem cache works. For other cachem mechanisms or settings, such as
#' an in-memory cache or size and age limits, set the option yourself, e.g. in
#' your `.Rprofile` so it applies every session:
#'
#' ```r
#' options(gsm.testdata_cache = cachem::cache_disk(
#'   "~/gsm-cache", max_size = 512 * 1024^2, max_age = 60 * 60 * 24 * 30
#' ))
#' options(gsm.testdata_cache = cachem::cache_mem())
#' ```
#'
#' In a running session, `gsm_testdata(cache = )` switches to any cachem cache
#' and sets the option.
#'
#' @param dir `character(1)` Directory for the disk cache, created if needed.
#'   Also accepts `NULL` (unset the option, returning to the default cache) or
#'   a value previously returned by this function, to restore it.
#' @returns `cachem` The previous value of the `gsm.testdata_cache` option,
#'   invisibly, so it can be restored with `use_testdata_cache_dir(old)`.
#' @seealso [gsm_testdata()] to inspect or clear the cache.
#' @examples
#' old <- use_testdata_cache_dir(file.path(tempdir(), "gsm-cache"))
#' gsm_testdata()$cache$info()$dir
#' use_testdata_cache_dir(old)
#' @export
use_testdata_cache_dir <- function(dir) {
  cache <- if (is.null(dir) || (!is.atomic(dir) && is.function(dir$get))) {
    dir
  } else if (rlang::is_string(dir) && nzchar(dir)) {
    cachem::cache_disk(dir)
  } else {
    cli::cli_abort(
      "{.arg dir} must be a single, non-empty string, {.code NULL}, or a
       previous return value."
    )
  }
  old <- getOption("gsm.testdata_cache")
  options(gsm.testdata_cache = cache)
  if (!is.null(gsm$testdata_handle)) {
    gsm$testdata_handle$set_cache(
      getOption("gsm.testdata_cache", .testdata_default_cache())
    )
  }
  invisible(old)
}

#' Apply the use_testdata_snapshot() setting to the handle
#'
#' @returns `FreshHandle` The handle, invisibly, or `NULL` if it doesn't exist
#'   yet.
#' @keywords internal
.testdata_apply_dir <- function() {
  handle <- gsm$testdata_handle
  if (is.null(handle)) {
    return(invisible())
  }
  handle$use_snapshot(.testdata_setting("testdata_dir"))
}

#' Read and validate a test data setting
#'
#' @param name `character(1)` `"testdata_dir"` or `"testdata_tag"`.
#' @param pattern `character(1)` Optional regex the value must match.
#' @returns `character(1)` The value, or `NULL` if unset (`NULL` or `""`).
#'   Validated here, on use, so bad environment variables can't break
#'   package loading.
#' @keywords internal
.testdata_setting <- function(name, pattern = NULL) {
  value <- gsm[[name]]
  if (is.null(value) || identical(value, "")) {
    return(NULL)
  }
  fn <- c(
    testdata_dir = "use_testdata_snapshot",
    testdata_tag = "use_testdata_tag"
  )[[name]]
  if (!rlang::is_string(value)) {
    cli::cli_abort("The value set by {.fn {fn}} must be a single string.")
  }
  if (!is.null(pattern) && !grepl(pattern, value)) {
    cli::cli_abort(
      "The value set by {.fn {fn}} ({.val {value}}) must match {.code {pattern}}."
    )
  }
  value
}

# Checker ---------------------------------------------------------------------

#' Choose the test data release to use
#'
#' @param state `FreshState` The handle's state store; the `"lookup"` entry
#'   records the last choice.
#' @returns `character(1)` The release tag. A tag holds exactly one data
#'   fingerprint, so caching values by tag also caches them by fingerprint.
#' @keywords internal
.testdata_checker <- function(state) {
  pinned <- .testdata_setting("testdata_tag", "^[A-Za-z0-9._-]+$")
  if (!is.null(pinned)) {
    .testdata_snapshot(pinned)
    return(pinned)
  }

  # Fast path: an exact match stays exact until installed packages change.
  prev <- state$get("lookup")
  if (
    identical(prev$match, "exact") &&
      identical(.testdata_installed(prev$packages), prev$installed)
  ) {
    return(prev$tag)
  }

  index <- tryCatch(.testdata_index(), error = function(e) {
    if (is.null(prev)) {
      cli::cli_abort(
        c(
          "Can't read the gsm.datasim test data index.",
          i = "Check your connection, or use {.fn use_testdata_snapshot}."
        ),
        parent = e
      )
    }
    cli::cli_inform(c(
      "Can't read the gsm.datasim test data index.",
      i = "Using the last chosen release, {.val {prev$tag}}."
    ))
    NULL
  })
  if (is.null(index)) {
    return(prev$tag)
  }

  installed <- .testdata_installed(index$packages)
  pick <- .testdata_select(index, installed)
  fingerprint <- pick$build$fingerprint
  tag <- index$fingerprints[[fingerprint]]$tag %||% pick$build$tag

  key <- .testdata_snapshot(tag)$key
  if (!identical(key, paste0("sha256:", fingerprint))) {
    cli::cli_abort(c(
      "Test data release {.val {tag}} doesn't match the index.",
      i = "Expected key {.val {paste0('sha256:', fingerprint)}}, got {.val {key}}."
    ))
  }
  state$set(
    "lookup",
    list(
      packages = index$packages,
      installed = installed,
      tag = tag,
      fingerprint = fingerprint,
      match = pick$match
    )
  )
  tag
}

#' Installed versions of the indexed packages
#'
#' A wrapper around [package_versions()] that tests can mock.
#'
#' @param packages `character` Package names.
#' @returns `list` Output of [package_versions()].
#' @keywords internal
.testdata_installed <- function(packages) {
  package_versions(packages) # nocov
}

#' Choose the build whose data matches the installed packages
#'
#' Lookup rule:
#'
#' 1. Exact: the installed packages' `inputs_hash` matches a build.
#' 2. Otherwise, filter builds package by package (in `index$packages` order):
#'    * not installed: no filter;
#'    * installed `RemoteSha` that appears in the index: same `remote_sha`;
#'    * otherwise (no `RemoteSha`, or an unbuilt one): same `version`, or if
#'      none of the remaining builds has it, `version <=` the installed one.
#' 3. Newest `built_at` among the survivors. Error if none survive.
#'
#' @param index `list` Output of [.testdata_parse_index()].
#' @param installed `list` Output of [package_versions()] for
#'   `index$packages`.
#' @returns `list` with `build` (one row of `index$builds`) and `match`
#'   (`"exact"` or `"filtered"`).
#' @keywords internal
.testdata_select <- function(index, installed) {
  builds <- index$builds
  if (!nrow(builds)) {
    cli::cli_abort("The gsm.datasim test data index has no builds.")
  }
  builds <- builds[order(builds$built_at, decreasing = TRUE), , drop = FALSE]
  pkgs <- index$packages
  installed <- lapply(rlang::set_names(pkgs), function(pkg) {
    installed[[pkg]] %||%
      list(version = NA_character_, remote_sha = NA_character_)
  })
  versions <- vapply(installed, function(p) p$version %||% NA_character_, "")

  if (!anyNA(versions)) {
    hit <- which(builds$inputs_hash == .testdata_inputs_hash(installed))
    if (length(hit)) {
      return(list(build = builds[hit[[1]], , drop = FALSE], match = "exact"))
    }
  }

  keep <- rep(TRUE, nrow(builds))
  for (pkg in pkgs) {
    version <- versions[[pkg]]
    if (is.na(version)) {
      next
    }
    sha <- installed[[pkg]]$remote_sha %||% NA_character_
    built_shas <- .testdata_build_field(builds, pkg, "remote_sha")
    built_versions <- .testdata_build_field(builds, pkg, "version")
    if (!is.na(sha) && sha %in% built_shas) {
      keep <- keep & built_shas %in% sha
    } else {
      same <- keep & built_versions %in% version
      keep <- if (any(same)) {
        same
      } else {
        keep & .testdata_version_le(built_versions, version)
      }
    }
    if (!any(keep)) {
      .testdata_abort_no_match(pkg, version, sha)
    }
  }
  list(build = builds[which(keep)[[1]], , drop = FALSE], match = "filtered")
}

#' Error for an installed package with no matching build
#'
#' @param pkg `character(1)` The package that removed the last build.
#' @param version `character(1)` Its installed version.
#' @param sha `character(1)` Its installed `RemoteSha`, or `NA`.
#' @returns Nothing; errors with class `gsm_testdata_no_match`.
#' @keywords internal
.testdata_abort_no_match <- function(pkg, version, sha) {
  installed <- if (is.na(sha)) {
    version
  } else {
    paste0(version, " (", substr(sha, 1, 7), ")")
  }
  cli::cli_abort(
    c(
      "No published gsm test data matches {.pkg {pkg}} {installed} together
       with your other installed gsm packages.",
      i = "{.pkg {pkg}} is probably out of step with the other gsm packages.
           Updating it (or them) to a compatible set usually fixes this.",
      i = "To use specific data anyway, see {.fn use_testdata_tag} or
           {.fn use_testdata_snapshot}."
    ),
    class = "gsm_testdata_no_match"
  )
}

#' One package field for every build
#'
#' @param builds `data.frame` `index$builds` from [.testdata_parse_index()].
#' @inheritParams .testdata_abort_no_match
#' @param field `character(1)` `"version"` or `"remote_sha"`.
#' @returns `character` One value per build (`NA` if missing).
#' @keywords internal
.testdata_build_field <- function(builds, pkg, field) {
  vapply(
    builds$packages,
    function(p) {
      value <- p[[field]][match(pkg, p$package)]
      if (!length(value) || is.na(value)) NA_character_ else as.character(value)
    },
    character(1)
  )
}

#' Which versions are at or below a maximum?
#'
#' @param versions `character` Versions to compare; `NA` gives `FALSE`.
#' @param max `character(1)` The maximum version.
#' @returns `logical` One value per element of `versions`.
#' @keywords internal
.testdata_version_le <- function(versions, max) {
  vapply(
    versions,
    function(v) !is.na(v) && utils::compareVersion(v, max) <= 0,
    logical(1),
    USE.NAMES = FALSE
  )
}

#' Hash of the packages that built a bundle
#'
#' Must match `gsm.datasim:::.inputs_hash()`: SHA-256 of one
#' `"<package> <version> <remote_sha>"` line per package (missing SHA as
#' `NA`), sorted by name in C-locale order and joined with `"\n"`.
#'
#' @param packages `list` Named by package; each element has `version`
#'   and `remote_sha`, as from [package_versions()].
#' @returns `character(1)` A 64-character hex string.
#' @keywords internal
.testdata_inputs_hash <- function(packages) {
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

# Release metadata ------------------------------------------------------------

#' Download and parse the test data index
#'
#' @returns `list` Output of [.testdata_parse_index()].
#' @keywords internal
.testdata_index <- function() {
  tmp <- tempfile(fileext = ".json")
  on.exit(unlink(tmp))
  safely_fetch(.testdata_index_url, tmp)
  .testdata_parse_index(jsonlite::read_json(tmp, simplifyVector = TRUE))
}

#' Validate and tidy the test data index
#'
#' @param index `list` `index.json` read with
#'   `jsonlite::read_json(simplifyVector = TRUE)`.
#' @returns `list` With `packages` (`character`), `fingerprints` (`list`), and
#'   `builds` (`data.frame`, excluding `override` builds).
#' @keywords internal
.testdata_parse_index <- function(index) {
  format <- index$format
  if (!is.numeric(format) || length(format) != 1) {
    cli::cli_abort("The test data index has no {.field format}.")
  }
  if (format > .testdata_index_format) {
    cli::cli_abort(c(
      "The test data index uses format {format}.",
      i = "Update gsm.core to read it (this version reads format
           {(.testdata_index_format)})."
    ))
  }
  builds <- index$builds
  if (!is.data.frame(builds) || !nrow(builds)) {
    builds <- data.frame(
      inputs_hash = character(),
      fingerprint = character(),
      tag = character(),
      source = character(),
      built_at = character()
    )
    builds$packages <- list()
  }
  builds <- builds[!builds$source %in% "override", , drop = FALSE]
  list(
    packages = as.character(index$packages),
    fingerprints = index$fingerprints %||% list(),
    builds = builds
  )
}

#' A release's snapshot.json
#'
#' Releases are immutable, so this is cached in memory and on disk
#' indefinitely.
#'
#' @inheritParams .testdata_url
#' @returns `list` Output of [parse_snapshot()].
#' @keywords internal
.testdata_snapshot <- function(tag) {
  if (!is.null(gsm$testdata_snapshots[[tag]])) {
    return(gsm$testdata_snapshots[[tag]])
  }
  path <- fs::path(.testdata_dir(), "snapshots", tag, ext = "json")
  if (!file.exists(path)) {
    tryCatch(
      safely_fetch(.testdata_url(tag, "snapshot.json"), path),
      error = function(e) {
        cli::cli_abort(
          "Can't find test data release {.val {tag}}.",
          parent = e
        )
      }
    )
  }
  snapshot <- parse_snapshot(jsonlite::read_json(path), source = tag)
  gsm$testdata_snapshots[[tag]] <- snapshot
  snapshot
}

#' One object's entry in a release's snapshot.json
#'
#' @inheritParams .testdata_url
#' @param object `character(1)` Object name.
#' @returns `list` With `file` and `sha256`.
#' @keywords internal
.testdata_object_entry <- function(tag, object) {
  entry <- .testdata_snapshot(tag)$objects[[object]]
  if (is.null(entry)) {
    cli::cli_abort("Test data release {.val {tag}} has no {.val {object}}.")
  }
  entry
}
