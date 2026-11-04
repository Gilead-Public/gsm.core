# Fake release server for testdata tests. Files live in
# `<root>/<tag>/<asset>`; requests for anything else fail like a 404.
local_fake_releases <- function(env = parent.frame()) {
  root <- withr::local_tempdir(.local_envir = env)
  requests <- character()

  publish <- function(tag, assets = list(), package_versions = list(),
                      pointer_channel = NULL) {
    dir <- file.path(root, tag)
    dir.create(dir, recursive = TRUE, showWarnings = FALSE)
    checksums <- list()
    for (name in names(assets)) {
      path <- file.path(dir, name)
      saveRDS(assets[[name]], path)
      checksums[[name]] <- unname(tools::sha256sum(path))
    }
    jsonlite::write_json(
      list(
        schema_version = 1, tag = tag, fingerprint = tag,
        package_versions = package_versions,
        checksums = list(sha256 = checksums)
      ),
      file.path(dir, "manifest.json"),
      auto_unbox = TRUE
    )
    if (!is.null(pointer_channel)) {
      latest <- file.path(root, paste0("testdata-", pointer_channel, "-latest"))
      dir.create(latest, showWarnings = FALSE)
      jsonlite::write_json(
        list(schema_version = 1, channel = pointer_channel, tag = tag),
        file.path(latest, "manifest.json"),
        auto_unbox = TRUE
      )
    }
    invisible(tag)
  }

  request <- function(url, dest) {
    requests <<- c(requests, url)
    rel <- sub("^.*/releases/download/", "", url)
    src <- file.path(root, rel)
    if (!file.exists(src)) stop("404: ", url)
    file.copy(src, dest, overwrite = TRUE)
    invisible(dest)
  }

  list(
    publish = publish,
    request = request,
    requests = function() requests,
    reset_requests = function() requests <<- character(),
    root = root
  )
}

pkg_state <- function(...) {
  lapply(list(...), function(x) {
    list(version = x[[1]], remote_sha = if (length(x) > 1) x[[2]] else NA_character_)
  })
}

manifest_versions <- function(...) {
  lapply(list(...), function(x) {
    out <- list(version = x[[1]])
    if (length(x) > 1) out$remote_sha <- x[[2]]
    out
  })
}

# A keep_fresh() handle with two bindings (a, b) whose setters count calls in
# `calls$n`.
new_counted_handle <- function(env = new.env(), key = "v1", ...) {
  calls <- new.env()
  calls$n <- 0
  handle <- keep_fresh(
    checker = function(state) key,
    setters = list(
      a = function(k) {
        calls$n <- calls$n + 1
        data.frame(x = 1:3, key = k)
      },
      b = function(k) {
        calls$n <- calls$n + 1
        list(k = k)
      }
    ),
    env = env,
    ...
  )
  list(handle = handle, env = env, calls = calls)
}
