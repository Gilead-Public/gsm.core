# Helpers for test-testdata.R and tests that use the real test data.

# Skip a test when gsm.datasim test data can't be loaded (e.g. offline with an
# empty cache). The result is remembered for the rest of the run.
skip_if_no_testdata <- function() {
  if (is.null(.testdata_available$ok)) {
    .testdata_available$ok <- testdata_is_available()
  }
  if (!.testdata_available$ok) {
    testthat::skip("gsm.datasim test data is unavailable.")
  }
  invisible(TRUE)
}
.testdata_available <- new.env(parent = emptyenv())

action_log_test_results <- function() {
  if (identical(Sys.getenv("CI"), "true")) {
    return(action_log_testdata()$reportingResults)
  }
  tryCatch(
    action_log_testdata()$reportingResults,
    error = function(error) testthat::skip("Matching ActionLog test data is unavailable.")
  )
}

# Fake gsm.datasim for testdata tests. Release assets live in
# `<root>/<tag>/<file>`, the data-index in `<root>/index.json`.
#
# `safely_fetch` stands in for refresh's safely_fetch() (see local_testdata_env()):
# it copies from `root`, fails like a 404 for anything missing, and records
# each URL and the checksum gsm.core asked for. Checksum verification itself
# is refresh's job and is tested in test-refresh-download.R.
local_fake_releases <- function(env = parent.frame()) {
  root <- withr::local_tempdir(.local_envir = env)
  requests <- character()
  checksums <- list()

  # Publish a `data-<fp12>` release: one RDS per object plus snapshot.json.
  # Returns the fingerprint.
  release <- function(objects = list(), fingerprint = NULL) {
    fingerprint <- fingerprint %||% digest::digest(objects, algo = "sha256")
    tag <- paste0("data-", substr(fingerprint, 1, 12))
    dir <- file.path(root, tag)
    dir.create(dir, recursive = TRUE, showWarnings = FALSE)
    files <- rlang::set_names(paste0(names(objects), ".rds"), names(objects))
    for (name in names(objects)) {
      saveRDS(objects[[name]], file.path(dir, files[[name]]))
    }
    write_snapshot_json(
      dir,
      objects = as.list(files),
      key = paste0("sha256:", fingerprint),
      metadata = list(fingerprint = fingerprint)
    )
    invisible(fingerprint)
  }

  # Write index.json (format 2) from builds made with helper_fake_build().
  index <- function(...) {
    builds <- list(...)
    pkgs <- sort(unique(unlist(lapply(builds, function(b) names(b$packages)))))
    fps <- unique(vapply(builds, `[[`, "", "fingerprint"))
    entries <- lapply(builds, function(b) {
      full <- lapply(rlang::set_names(pkgs), function(p) {
        b$packages[[p]] %||% list(version = NA, remote_sha = NA)
      })
      list(
        inputs_hash = .testdata_inputs_hash(full),
        fingerprint = b$fingerprint,
        tag = paste0("data-", substr(b$fingerprint, 1, 12)),
        source = b$source,
        built_at = b$built_at,
        packages = unname(lapply(pkgs, function(p) {
          na_null <- function(x) if (is.null(x) || is.na(x)) NULL else x
          list(
            package = p,
            version = na_null(full[[p]]$version),
            remote_sha = na_null(full[[p]]$remote_sha)
          )
        }))
      )
    })
    jsonlite::write_json(
      list(
        format = 2,
        packages = pkgs,
        fingerprints = lapply(rlang::set_names(fps), function(fp) {
          list(tag = paste0("data-", substr(fp, 1, 12)), first_built_at = "x")
        }),
        builds = entries
      ),
      file.path(root, "index.json"),
      auto_unbox = TRUE,
      null = "null",
      pretty = TRUE
    )
    invisible(entries)
  }

  safely_fetch <- function(
    url,
    dest,
    checksum = NULL,
    downloader = fetch_binary
  ) {
    requests <<- c(requests, url)
    checksums[url] <<- list(checksum)
    rel <- if (grepl("/data-index/index\\.json$", url)) {
      "index.json"
    } else {
      sub("^.*/releases/download/", "", url)
    }
    src <- file.path(root, rel)
    if (!file.exists(src)) {
      stop("404: ", url)
    }
    dir.create(dirname(dest), recursive = TRUE, showWarnings = FALSE)
    file.copy(src, dest, overwrite = TRUE)
    invisible(dest)
  }

  list(
    release = release,
    index = index,
    safely_fetch = safely_fetch,
    requests = function() requests,
    checksums = function() checksums,
    reset_requests = function() requests <<- character(),
    root = root
  )
}

# A build entry for the fake index. `packages` is from helper_pkg_state() (in
# helper-refresh.R).
helper_fake_build <- function(
  fingerprint,
  packages,
  built_at = "2026-01-01T00:00:00Z",
  source = "dev"
) {
  list(
    fingerprint = fingerprint,
    packages = packages,
    built_at = built_at,
    source = source
  )
}

# Isolate cache, settings, snapshot memo, and network for one test.
# `installed` is a function returning helper_pkg_state() output.
local_testdata_env <- function(server, installed, env = parent.frame()) {
  cache <- withr::local_tempdir(.local_envir = env)
  local_testdata_settings(env = env)
  withr::local_options(gsm.testdata_cache = NULL, .local_envir = env)
  testthat::local_mocked_bindings(
    .testdata_dir = function() cache,
    safely_fetch = server$safely_fetch,
    .testdata_installed = function(pkgs) {
      have <- installed()
      lapply(rlang::set_names(pkgs), function(p) {
        have[[p]] %||% list(version = NA_character_, remote_sha = NA_character_)
      })
    },
    .env = env
  )
  clear_testdata_snapshots()
  withr::defer(clear_testdata_snapshots(), envir = env)
  invisible(cache)
}

clear_testdata_snapshots <- function() {
  gsm$testdata_snapshots <- NULL
}

# Clear gsm.core's test data settings and handle for one test, restoring them
# afterwards.
local_testdata_settings <- function(env = parent.frame()) {
  names <- c("testdata_dir", "testdata_tag", "testdata_handle")
  old <- mget(names, envir = gsm, ifnotfound = list(NULL))
  withr::defer(
    for (n in names) {
      assign(n, old[[n]], envir = gsm)
    },
    envir = env
  )
  for (n in names) {
    assign(n, NULL, envir = gsm)
  }
  invisible()
}

# Run the gsm checker against the state file in a test cache dir.
helper_run_checker <- function(cache) {
  .testdata_checker(state_file(file.path(cache, "testdata-state.rds")))
}

# Parse a fake index the way .testdata_index() does.
helper_fake_index <- function(...) {
  server <- local_fake_releases()
  server$index(...)
  .testdata_parse_index(
    jsonlite::read_json(
      file.path(server$root, "index.json"),
      simplifyVector = TRUE
    )
  )
}

# Fingerprint chosen by .testdata_select().
helper_select_fingerprint <- function(index, installed) {
  .testdata_select(index, installed)$build$fingerprint
}
