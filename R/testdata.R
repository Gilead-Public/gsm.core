# gsm.datasim test data served via keep_fresh() (see R/refresh*.R) -----------
#
# Releases (see #206):
#   testdata-<channel>-<timestamp>  immutable; assets + full manifest.json
#   testdata-<channel>-latest       pointer manifest.json with `tag`
#
# Settings live in `gsm` (see gsm_testdata_use_dir() etc.). Their defaults read
# GSM_TESTDATA_DIR / GSM_TESTDATA_TAG / GSM_TESTDATA_CHANNEL; .onLoad calls them.

# Package-level state. Read as gsm$testdata_dir, gsm$testdata_handle, etc.
gsm <- new.env(parent = emptyenv())

#' @evalNamespace fresh_exports(names(.testdata_assets))
NULL
.testdata_assets <- c(
  analyticsInput2 = "analyticsInput.rds",
  lSource2 = "lSource.rds"
)

#' analyticsInput2 Dataset (experimental)
#'
#' `r lifecycle::badge("experimental")`
#'
#' Downloaded on first use from a gsm.datasim test data release and cached in
#' `tools::R_user_dir("gsm", "cache")`. The cache is refreshed when installed
#' gsm packages are newer than the ones that built the cached bundle.
#'
#' @format A data frame with one row per subject and metric:
#' \describe{
#'   \item{SubjectID}{unique subject identifier}
#'   \item{GroupID}{grouping variable}
#'   \item{GroupLevel}{level of grouping variable}
#'   \item{Numerator}{number of flags in group}
#'   \item{Denominator}{total subjects in group}
#'   \item{Metric}{calculated rate/metric value}
#' }
#' @inheritSection lSource2 Release selection
#' @source `analyticsInput.rds` from a `testdata-*` release of
#'   <https://github.com/Gilead-Public/gsm.datasim/releases>.
#' @name analyticsInput2
#' @docType data
#' @usage analyticsInput2
#' @keywords datasets
NULL

#' lSource2 Dataset (experimental)
#'
#' `r lifecycle::badge("experimental")`
#'
#' Downloaded on first use from a gsm.datasim test data release and cached in
#' `tools::R_user_dir("gsm", "cache")`. The cache is refreshed when installed
#' gsm packages are newer than the ones that built the cached bundle.
#'
#' @format A named list of data frames, one per raw source domain (e.g.
#'   `Raw_AE`, `Raw_SUBJ`, `Raw_SITE`), representing a single study snapshot.
#'   See [lSource] for the full list of domains.
#' @section Release selection:
#' The release is chosen by, in order of priority:
#' * [gsm_testdata_use_dir()]: a local folder containing `manifest.json` and
#'   the `.rds` assets. Nothing is downloaded or cached.
#' * [gsm_testdata_use_tag()]: an exact release tag.
#' * [gsm_testdata_use_channel()]: the latest release in that channel.
#' * Otherwise the `dev` channel if any relevant installed gsm package has a
#'   development (four-part) version, else `prod`.
#'
#' Each can also be set with an environment variable before gsm.core loads;
#' see [gsm_testdata_use_dir()].
#' @source `lSource.rds` from a `testdata-*` release of
#'   <https://github.com/Gilead-Public/gsm.datasim/releases>.
#' @name lSource2
#' @docType data
#' @usage lSource2
#' @keywords datasets
NULL

.testdata_repo <- "Gilead-Public/gsm.datasim"

.testdata_dir <- function() {
  tools::R_user_dir("gsm", "cache")
}

.testdata_url <- function(tag, asset) {
  sprintf(
    "https://github.com/%s/releases/download/%s/%s",
    .testdata_repo, tag, asset
  )
}

.register_testdata <- function(env,
                               cache = getOption(
                                 "gsm.testdata_cache",
                                 .testdata_default_cache()
                               )) {
  setters <- lapply(.testdata_assets, function(asset) {
    remote <- download_setter(
      url = function(tag) .testdata_url(tag, asset),
      checksum = function(tag) .testdata_manifest(tag)$checksums$sha256[[asset]]
    )
    function(key) {
      if (is.list(key) && !is.null(key$dir)) {
        .testdata_read_local(key$dir, asset)
      } else {
        remote(key)
      }
    }
  })
  gsm$testdata_handle <- keep_fresh(
    checker = .testdata_checker,
    setters = setters,
    env = env,
    cache = cache,
    state = state_file(file.path(.testdata_dir(), "testdata-state.rds"))
  )
  invisible(gsm$testdata_handle)
}

.testdata_default_cache <- function() {
  cachem::cache_disk(file.path(.testdata_dir(), "values"))
}

#' Inspect and manage the cached test data
#'
#' `r lifecycle::badge("experimental")`
#'
#' The test data objects (e.g. [analyticsInput2]) are cached in a standard
#' \pkg{cachem} cache. `gsm_testdata()` returns a handle for inspecting and
#' managing it, and can switch to a different cache.
#'
#' By default the cache is `cachem::cache_disk()` in
#' `tools::R_user_dir("gsm", "cache")` (set `R_USER_CACHE_DIR` to move it),
#' with cachem's default size limit and no age limit. To use different
#' settings, pass any cachem cache to `gsm_testdata(cache = )`, or set the
#' `gsm.testdata_cache` option (e.g. in your `.Rprofile`) to apply it every
#' session:
#'
#' ```r
#' options(gsm.testdata_cache = cachem::cache_disk(
#'   "~/gsm-cache", max_size = 512 * 1024^2, max_age = 60 * 60 * 24 * 30
#' ))
#' ```
#'
#' @param cache A \pkg{cachem} cache to use from now on. Defaults to the
#'   `gsm.testdata_cache` option; `NULL` keeps the current cache. A new cache
#'   is also stored in that option for the rest of the session. Objects
#'   already loaded this session stay in memory; later loads use the new
#'   cache.
#' @returns A `FreshHandle` R6 object with
#' * `key()`: the release tag currently in use.
#' * `refresh()`: check for a newer release now.
#' * `reset()`: forget the release choice and recorded package versions, so
#'   the next access re-resolves everything. Cached values are kept.
#' * `set_cache(cache)`: switch caches without changing the option.
#' * `cache`: the current cachem object. Use its methods directly, e.g.
#'   `gsm_testdata()$cache$size()`, `$keys()`, `$prune()`, `$reset()`
#'   (delete all cached values), or `$destroy()`.
#' * `state`: the store that records the chosen release and package
#'   versions; `state$path` shows where it's saved.
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

# Settings --------------------------------------------------------------------

#' Choose which test data gsm.core uses
#'
#' `r lifecycle::badge("experimental")`
#'
#' These functions control where the test data objects (e.g.
#' [analyticsInput2]) come from, in order of priority:
#'
#' * `gsm_testdata_use_dir()`: read from a local folder containing
#'   `manifest.json` and the `.rds` assets, e.g. for offline work or to test
#'   an unpublished bundle. Nothing is downloaded or cached. The folder is used
#'   even if installed packages are newer than the bundle (with a message).
#' * `gsm_testdata_use_tag()`: use one exact gsm.datasim release, e.g.
#'   `"testdata-dev-20261030T182506Z"`.
#' * `gsm_testdata_use_channel()`: use the latest release in a channel, e.g.
#'   `"dev"` or `"prod"`.
#'
#' If none is set, gsm.core uses the `dev` channel when any relevant installed
#' gsm package has a development (four-part) version, and `prod` otherwise.
#'
#' Each function's default reads an environment variable
#' (`GSM_TESTDATA_DIR`, `GSM_TESTDATA_TAG`, `GSM_TESTDATA_CHANNEL`).
#' gsm.core calls all three with their defaults when it loads, so setting the
#' variables (e.g. in `.Renviron` or CI) applies them every session. Calling a
#' function changes the setting for the current session only.
#'
#' Values are checked when the test data is next accessed, not when they're
#' set.
#'
#' @param dir Path to a local bundle folder. `NULL` or `""` stops using one.
#' @param tag A release tag. `NULL` or `""` stops pinning one.
#' @param channel A channel name (lowercase letters and digits). `NULL` or
#'   `""` chooses automatically.
#' @returns The previous value, invisibly, so it can be restored later.
#' @examples
#' old <- gsm_testdata_use_channel("prod")
#' gsm_testdata_use_channel(old)
#'
#' # Re-read the environment variable:
#' gsm_testdata_use_channel()
#'
#' # Temporarily, e.g. in a test:
#' # withr::defer(gsm_testdata_use_tag(gsm_testdata_use_tag("testdata-...")))
#' @export
gsm_testdata_use_dir <- function(dir = Sys.getenv("GSM_TESTDATA_DIR")) {
  .testdata_set("testdata_dir", dir)
}

#' @rdname gsm_testdata_use_dir
#' @export
gsm_testdata_use_tag <- function(tag = Sys.getenv("GSM_TESTDATA_TAG")) {
  .testdata_set("testdata_tag", tag)
}

#' @rdname gsm_testdata_use_dir
#' @export
gsm_testdata_use_channel <- function(channel = Sys.getenv("GSM_TESTDATA_CHANNEL")) {
  .testdata_set("testdata_channel", channel)
}

.testdata_set <- function(name, value) {
  old <- gsm[[name]]
  assign(name, value, envir = gsm)
  if (!is.null(gsm$testdata_handle)) {
    gsm$testdata_handle$invalidate()
  }
  invisible(old)
}

# Returns a setting, or NULL if unset (NULL or ""). Validates on use so bad
# environment variables can't break package loading.
.testdata_setting <- function(name, pattern = NULL) {
  value <- gsm[[name]]
  if (is.null(value) || identical(value, "")) {
    return(NULL)
  }
  fn <- paste0("gsm_testdata_use_", sub("^testdata_", "", name))
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

.testdata_checker <- function(state) {
  dir <- .testdata_setting("testdata_dir")
  if (!is.null(dir)) {
    return(.testdata_check_local(dir, state))
  }

  pinned <- .testdata_setting("testdata_tag")
  if (!is.null(pinned)) {
    state$set("package_versions", .testdata_manifest(pinned)$package_versions)
    return(pinned)
  }

  installed <- .testdata_installed(.testdata_candidates(state))
  channel <- .testdata_channel(installed)
  slot <- paste0("channel_", channel)
  prev <- state$get(slot)

  # Fast path: nothing installed changed, or nothing is newer than the bundle.
  if (!is.null(prev)) {
    unchanged <- identical(installed, prev$installed)
    if (unchanged ||
        !.testdata_is_outdated(installed, .testdata_manifest(prev$tag))) {
      if (!unchanged) {
        prev$installed <- installed
        state$set(slot, prev)
      }
      return(prev$tag)
    }
  }

  tag <- .testdata_pointer(channel)
  manifest <- .testdata_manifest(tag)
  if (.testdata_is_outdated(installed, manifest)) {
    cli::cli_inform(c(
      "Installed packages are newer than the latest {.val {channel}} test data.",
      i = "Using {.val {tag}}."
    ))
  }
  state$set(slot, list(installed = installed, tag = tag))
  state$set("package_versions", manifest$package_versions)
  tag
}

# gsm_testdata_use_dir(): a local bundle (manifest.json + assets). Never touches the
# network or the value cache; stale bundles are used with a message.
.testdata_check_local <- function(dir, state) {
  manifest <- .testdata_local_manifest(dir)
  installed <- .testdata_installed(.testdata_candidates(state))
  if (.testdata_is_outdated(installed, manifest)) {
    cli::cli_inform(c(
      "Installed packages are newer than the test data in {.path {dir}}.",
      i = "Using it anyway because {.fn gsm_testdata_use_dir} is set."
    ))
  }
  state$set("package_versions", manifest$package_versions)
  uncached(list(
    dir = normalizePath(dir, winslash = "/"),
    fingerprint = manifest$fingerprint
  ))
}

.testdata_local_manifest <- function(dir) {
  if (!dir.exists(dir)) {
    cli::cli_abort(
      "Test data directory {.path {dir}} does not exist."
    )
  }
  path <- file.path(dir, "manifest.json")
  if (!file.exists(path)) {
    cli::cli_abort(
      "No {.file manifest.json} in test data directory {.path {dir}}."
    )
  }
  jsonlite::read_json(path)
}

.testdata_read_local <- function(dir, asset) {
  path <- file.path(dir, asset)
  if (!file.exists(path)) {
    cli::cli_abort("{.file {asset}} not found in {.path {dir}}.")
  }
  expected <- .testdata_local_manifest(dir)$checksums$sha256[[asset]]
  if (!is.null(expected)) {
    actual <- unname(tools::sha256sum(path))
    if (!identical(tolower(actual), tolower(expected))) {
      cli::cli_abort(c(
        "Checksum mismatch for {.path {path}}.",
        i = "Expected {.val {expected}}, got {.val {actual}}."
      ))
    }
  }
  readRDS(path)
}

# gsm.core, plus anything gsm-ish installed, plus whatever the last manifest
# said mattered. Solves the "which packages decide the channel" bootstrap.
.testdata_candidates <- function(state) {
  installed <- unique(unlist(lapply(
    .libPaths(),
    list.files,
    pattern = "^gsm\\.[A-Za-z0-9.]+$"
  )))
  known <- names(state$get("package_versions"))
  sort(setdiff(unique(c("gsm.core", "workr", installed, known)), "R"))
}

.testdata_installed <- function(pkgs) {
  package_versions(setdiff(pkgs, "R"))
}

.testdata_channel <- function(installed) {
  channel <- .testdata_setting("testdata_channel", "^[a-z0-9]+$")
  if (!is.null(channel)) {
    return(channel)
  }
  versions <- stats::na.omit(vapply(installed, `[[`, character(1), "version"))
  is_dev <- any(lengths(strsplit(versions, "[.-]")) >= 4)
  if (is_dev) "dev" else "prod"
}

# TRUE if any installed package is newer than what built the bundle, or has
# the same version from a different commit.
.testdata_is_outdated <- function(installed, manifest) {
  length(packages_newer(installed, manifest$package_versions)) > 0
}

# Release metadata ------------------------------------------------------------

.testdata_manifests <- new.env(parent = emptyenv())

# Manifests of immutable tags never change, so cache them indefinitely.
.testdata_manifest <- function(tag) {
  if (!is.null(.testdata_manifests[[tag]])) {
    return(.testdata_manifests[[tag]])
  }
  path <- file.path(.testdata_dir(), "manifests", paste0(tag, ".json"))
  if (!file.exists(path)) {
    fetch_file(.testdata_url(tag, "manifest.json"), path)
  }
  manifest <- jsonlite::read_json(path)
  assign(tag, manifest, envir = .testdata_manifests)
  manifest
}

.testdata_pointer <- function(channel) {
  release <- paste0("testdata-", channel, "-latest")
  tmp <- tempfile(fileext = ".json")
  on.exit(unlink(tmp))
  tryCatch(
    fetch_file(.testdata_url(release, "manifest.json"), tmp),
    error = function(e) {
      cli::cli_abort(
        c(
          "No {.val {channel}} test data release found ({.val {release}}).",
          i = "Use {.fn gsm_testdata_use_channel} or {.fn gsm_testdata_use_tag}."
        ),
        parent = e
      )
    }
  )
  tag <- jsonlite::read_json(tmp)$tag
  if (is.null(tag)) {
    cli::cli_abort("{.val {release}} manifest has no {.field tag}.")
  }
  tag
}
