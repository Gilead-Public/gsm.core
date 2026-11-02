# Spike for #206: cached, auto-refreshing data objects via active bindings.
#
# Staleness rule:
#   1. Fast path (no network): if the installed versions/SHAs of the packages
#      listed in the cached manifest are identical to the snapshot taken at the
#      last check, the cache is fresh.
#   2. Otherwise compare installed packages against the cached manifest. If
#      any installed version is newer, or the version matches but the RemoteSha
#      differs, fetch the remote manifest. If its fingerprint differs from
#      the cached one, delete the cached assets so they're re-downloaded lazily.
#   3. Record the current installed snapshot so step 1 short-circuits next
#      time, even if the remote bundle hasn't caught up yet.

.fresh_tag <- "testdata-bundle-test-151"

.fresh_url <- function(asset, tag = .fresh_tag) {
  sprintf(
    "https://github.com/Gilead-Public/gsm.datasim/releases/download/%s/%s",
    tag, asset
  )
}

.fresh_cache_dir <- function() {
  tools::R_user_dir("gsm", "cache")
}

.fresh_download <- function(asset, path) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  tmp <- tempfile()
  on.exit(unlink(tmp))
  utils::download.file(.fresh_url(asset), tmp, mode = "wb", quiet = TRUE)
  file.copy(tmp, path, overwrite = TRUE)
}

.fresh_read_manifest <- function(path) {
  jsonlite::fromJSON(path, simplifyVector = FALSE)
}

# Installed Version/RemoteSha for each package; NA if not installed.
.fresh_installed_state <- function(pkgs) {
  pkgs <- setdiff(pkgs, "R")
  lapply(rlang::set_names(pkgs), function(pkg) {
    desc <- suppressWarnings(
      utils::packageDescription(pkg, fields = c("Version", "RemoteSha"))
    )
    if (!is.list(desc)) {
      return(list(version = NA_character_, remote_sha = NA_character_))
    }
    list(version = desc$Version, remote_sha = desc$RemoteSha)
  })
}

# TRUE if any installed package appears newer than what the bundle used.
.fresh_is_outdated <- function(installed, manifest) {
  built <- manifest$package_versions
  any(vapply(names(installed), function(pkg) {
    inst <- installed[[pkg]]
    ref <- built[[pkg]]
    if (is.na(inst$version) || is.null(ref)) {
      return(FALSE)
    }
    cmp <- utils::compareVersion(inst$version, ref$version)
    if (cmp != 0) {
      return(cmp > 0)
    }
    # Same version: SHAs can't be ordered offline, so any mismatch triggers a
    # (cheap) remote manifest check.
    !is.na(inst$remote_sha) && !is.null(ref$remote_sha) &&
      !identical(inst$remote_sha, ref$remote_sha)
  }, logical(1)))
}

.fresh_env <- new.env(parent = emptyenv())

# Ensures the local manifest is current; runs at most once per session.
.fresh_sync <- function(force = FALSE) {
  if (isTRUE(.fresh_env$synced) && !force) {
    return(invisible())
  }
  dir <- .fresh_cache_dir()
  manifest_path <- file.path(dir, "manifest.json")
  state_path <- file.path(dir, "state.rds")

  if (!file.exists(manifest_path)) {
    .fresh_download("manifest.json", manifest_path)
  }
  manifest <- .fresh_read_manifest(manifest_path)
  installed <- .fresh_installed_state(names(manifest$package_versions))
  state <- if (file.exists(state_path)) readRDS(state_path)

  unchanged <- identical(installed, state$installed) &&
    identical(manifest$fingerprint, state$fingerprint)
  if (!unchanged && .fresh_is_outdated(installed, manifest)) {
    remote_path <- tempfile(fileext = ".json")
    on.exit(unlink(remote_path), add = TRUE)
    .fresh_download("manifest.json", remote_path)
    remote <- .fresh_read_manifest(remote_path)
    if (!identical(remote$fingerprint, manifest$fingerprint)) {
      cli::cli_inform("Newer gsm.datasim bundle found; refreshing cache.")
      unlink(setdiff(list.files(dir, full.names = TRUE), state_path))
      file.copy(remote_path, manifest_path, overwrite = TRUE)
      manifest <- remote
      .fresh_env$values <- list()
    } else if (.fresh_is_outdated(installed, remote)) {
      cli::cli_inform(
        "Installed packages are newer than the latest gsm.datasim bundle."
      )
    }
  }
  saveRDS(list(installed = installed, fingerprint = manifest$fingerprint),
          state_path)
  .fresh_env$synced <- TRUE
  invisible()
}

fresh_binding <- function(asset) {
  force(asset)
  function(v) {
    if (!missing(v)) {
      cli::cli_abort("{.val {asset}} is read-only.")
    }
    .fresh_sync()
    if (is.null(.fresh_env$values[[asset]])) {
      path <- file.path(.fresh_cache_dir(), asset)
      if (!file.exists(path)) {
        cli::cli_inform("Downloading {.file {asset}}.")
        .fresh_download(asset, path)
      }
      .fresh_env$values[[asset]] <- readRDS(path)
    }
    .fresh_env$values[[asset]]
  }
}

.register_fresh_bindings <- function(ns) {
  .fresh_env$values <- list()
  makeActiveBinding("analyticsInput2", fresh_binding("analyticsInput.rds"), ns)
}
