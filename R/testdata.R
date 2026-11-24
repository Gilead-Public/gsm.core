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
    fetch <- construct_fetcher(
      url_constructor = function(tag) {
        .testdata_url(tag, .testdata_object_entry(tag, object)$file)
      },
      digest_finder = function(tag) .testdata_object_entry(tag, object)$digest
    )
    function(tag) {
      # A local build with the same fingerprint holds the same data, so copy
      # from it instead of downloading.
      snapshot <- .testdata_snapshot(tag)
      if (is.null(snapshot$dir)) {
        return(fetch(tag))
      }
      tryCatch(
        {
          .testdata_object_entry(tag, object)
          .snapshot_read_object(snapshot, object)
        },
        error = function(e) {
          # Damaged local copy: download the release instead, if there is one.
          gsm$testdata_snapshots[[tag]] <- NULL
          release <- tryCatch(
            .testdata_snapshot(tag, local = FALSE),
            error = function(e2) NULL
          )
          if (is.null(release)) {
            gsm$testdata_snapshots[[tag]] <- snapshot
            rlang::cnd_signal(e)
          }
          fetch(tag)
        }
      )
    }
  })
  gsm$testdata_handle <- keep_fresh(
    checker = .testdata_checker,
    setters = setters,
    env = env,
    cache = cache,
    state = state_file(function() {
      file.path(.testdata_dir(), "testdata-state.rds")
    }),
    snapshot_names = .testdata_objects,
    on_error = .testdata_on_error
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

#' Turn a failed test data read into a warning
#'
#' Test data is a development convenience, so a failure shouldn't stop work
#' (or package installation, which reads every binding).
#'
#' @param cnd `condition` The error.
#' @param name `character(1)` The binding name.
#' @returns `NULL`, with a `gsm_testdata_unavailable` warning (a silent
#'   condition of the same class in R CMD INSTALL/check, so it can't add
#'   warnings to their logs).
#' @keywords internal
.testdata_on_error <- function(cnd, name) {
  if (.testdata_quiet_context()) {
    rlang::signal(
      "gsm test data is unavailable.",
      class = "gsm_testdata_unavailable",
      parent = cnd
    )
    return(NULL)
  }
  cli::cli_warn(
    c(
      "gsm test data {.val {name}} is unavailable; returning {.code NULL}.",
      i = "See {.help gsm.core::lSource} for how test data is chosen."
    ),
    parent = cnd,
    class = "gsm_testdata_unavailable"
  )
  NULL
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
    gsm_testdata_unavailable = function(w) FALSE,
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

  # Fast path: an exact match stays exact until installed packages change, and
  # so does a local build (until it's rebuilt or removed).
  prev <- state$get("lookup")
  tryCatch(
    .testdata_lookup(state, prev),
    error = function(e) {
      # Dev tooling shouldn't stop work over a lookup problem: fall back to the
      # last data used, if any.
      if (is.null(prev$tag)) {
        rlang::cnd_signal(e)
      }
      .testdata_fallback_warn(prev$tag, e)
      prev$tag
    }
  )
}

#' Warn that test data fell back to the last release
#'
#' A silent condition of the same class in R CMD INSTALL/check, so it can't
#' add warnings to their logs but can still be caught.
#'
#' @param tag `character(1)` The release used.
#' @param cnd `condition` Why the lookup failed.
#' @returns `NULL`, invisibly.
#' @keywords internal
.testdata_fallback_warn <- function(tag, cnd) {
  if (.testdata_quiet_context()) {
    rlang::signal(
      "Using the last chosen gsm test data release.",
      class = "gsm_testdata_fallback",
      parent = cnd
    )
    return(invisible())
  }
  cli::cli_warn(
    c(
      "Can't find gsm test data matching your installed packages.",
      i = "Using the last chosen release, {.val {tag}}, which may not
           match them."
    ),
    parent = cnd,
    class = "gsm_testdata_fallback"
  )
  invisible()
}

#' Look up the test data release for the installed packages
#'
#' The body of [.testdata_checker()], without its fallback.
#'
#' @inheritParams .testdata_checker
#' @param prev `list` The previous `"lookup"` state entry, or `NULL`.
#' @returns `character(1)` The release tag.
#' @keywords internal
.testdata_lookup <- function(state, prev) {
  if (
    isTRUE(prev$match %in% c("exact", "local")) &&
      identical(.testdata_installed(prev$packages), prev$installed)
  ) {
    if (identical(prev$match, "exact")) {
      return(prev$tag)
    }
    # Reuse an existing build even without the builder option (e.g. in
    # non-interactive processes like R CMD INSTALL); the builder is only
    # resolved if a build is needed.
    if (.testdata_local_exists(prev$dir)) {
      return(.testdata_use_local(state, prev$packages, prev$installed))
    }
  }

  index <- tryCatch(.testdata_index(), error = function(e) {
    # Without the index, a local build matching the installed packages is the
    # best data available.
    local <- .testdata_local_match()
    if (!is.null(local)) {
      return(structure(list(dir = local), class = "gsm_local_match"))
    }
    # The last choice is still right if no package changed since; otherwise
    # the checker falls back to it with a warning.
    if (
      !is.null(prev$tag) &&
        identical(.testdata_installed(prev$packages), prev$installed)
    ) {
      cli::cli_inform(c(
        "Can't read the gsm.datasim test data index.",
        i = "Using the last chosen release, {.val {prev$tag}}."
      ))
      return(NULL)
    }
    cli::cli_abort(
      c(
        "Can't read the gsm.datasim test data index.",
        i = "Check your connection, or use {.fn use_testdata_snapshot}."
      ),
      parent = e
    )
  })
  if (is.null(index)) {
    return(prev$tag)
  }
  if (inherits(index, "gsm_local_match")) {
    packages <- .testdata_local_packages(index$dir)
    return(.testdata_use_local(state, packages, .testdata_installed(packages)))
  }

  installed <- .testdata_installed(index$packages)
  # A matching local build is used even without the builder option, which is
  # only needed to make a new one.
  if (
    .testdata_has_local_pkg(installed) &&
      (.testdata_local_exists(.testdata_local_dir(installed)) ||
        !is.null(getOption("gsm.testdata_builder")))
  ) {
    pick <- if (nrow(index$builds)) {
      tryCatch(
        .testdata_select(index, installed),
        gsm_testdata_no_match = function(e) NULL
      )
    }
    if (!identical(pick$match, "exact")) {
      return(.testdata_use_local(state, index$packages, installed))
    }
  } else {
    pick <- .testdata_select(index, installed)
  }
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
    hit <- which(builds$inputs_hash == fresh_inputs_hash(installed))
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
           {.fn use_testdata_snapshot}.",
      if (is.null(getOption("gsm.testdata_builder"))) {
        c(
          i = "To build test data from your local packages instead, set
               {.code options(gsm.testdata_builder =
               \"gsm.datasim::build_testdata_bundle\")}."
        )
      }
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
#' indefinitely. If a local build (see [rebuild_local_testdata()]) has the
#' same fingerprint, its snapshot is used instead, with `dir` set, so objects
#' are copied from it rather than downloaded.
#'
#' @inheritParams .testdata_url
#' @param local `logical(1)` Use a matching local build if there is one?
#' @returns `list` Output of [parse_snapshot()].
#' @keywords internal
.testdata_snapshot <- function(tag, local = TRUE) {
  if (!is.null(gsm$testdata_snapshots[[tag]])) {
    return(gsm$testdata_snapshots[[tag]])
  }
  local <- if (local) .testdata_local_find(tag)
  if (!is.null(local)) {
    gsm$testdata_snapshots[[tag]] <- local
    return(local)
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
#' @returns `list` With `file` and `digest`.
#' @keywords internal
.testdata_object_entry <- function(tag, object) {
  entry <- .testdata_snapshot(tag)$objects[[object]]
  if (is.null(entry)) {
    cli::cli_abort("Test data release {.val {tag}} has no {.val {object}}.")
  }
  entry
}
