# A fake file server for download tests: `url` maps to `<root>/<path>`, where
# `path` is everything after the host. Missing files fail like a 404.
local_file_server <- function(env = parent.frame()) {
  root <- withr::local_tempdir(.local_envir = env)
  downloader <- function(url, dest) {
    src <- file.path(root, sub("^[a-z]+://[^/]+/", "", url))
    if (!file.exists(src)) {
      stop("404: ", url)
    }
    file.copy(src, dest, overwrite = TRUE)
    invisible(dest)
  }
  list(root = root, downloader = downloader)
}

helper_pkg_state <- function(...) {
  lapply(list(...), function(x) {
    list(
      version = x[[1]],
      remote_sha = if (length(x) > 1) x[[2]] else NA_character_
    )
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
