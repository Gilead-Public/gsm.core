# refresh: keep objects in an environment fresh ------------------------------
#
# Everything in R/refresh*.R is written as if it lived in a separate package
# ("refresh"). It must not reference anything gsm-specific.

#' Bind objects into an environment and keep them fresh
#'
#' Makes objects that look like ordinary variables but always hold an
#' up-to-date value, built only when it's first needed. Use it for data that
#' lives elsewhere (e.g. a download) and changes occasionally: users keep
#' writing `pkg::my_data` and get the current version without calling a
#' function.
#'
#' Supply a `checker` that reports which version of the data is current, and
#' one `setter` per object that builds that object for a given version. Call
#' `keep_fresh()` from your package's `.onLoad()` with `env` set to the package
#' namespace, and export the objects with `fresh_exports()`. Values are stored
#' in `cache`, so a setter only runs again when `checker` reports a new
#' version.
#'
#' The cache is a standard \pkg{cachem} object, so you (and your users) can
#' choose its location, size limits, and age limits, inspect it, or prune it
#' with the usual cachem methods. Packages that use `keep_fresh()` should let
#' users supply their own cache (e.g. via an option) and expose the handle's
#' `cache` so it's never hidden.
#'
#' @param checker `function(state)` returning a version key (any R object,
#'   compared with [identical()]). `state` is the `state` store, so the checker
#'   can remember things between checks (e.g. to skip expensive remote
#'   checks).
#' @param setters Named list of `function(key)` returning the value for that
#'   name at version `key`.
#' @param env Environment (or unlocked namespace) to create the bindings in.
#' @param cache A \pkg{cachem} cache, such as [cachem::cache_mem()] (the
#'   default; values last for the session) or [cachem::cache_disk()] (values
#'   persist across sessions). Any object with `get()`, `set()`, and
#'   `exists()` methods in the cachem style works.
#' @param state Where `checker` keeps its state: `state_memory()` (the
#'   default) or `state_file()` to persist it across sessions. Kept separate
#'   from `cache` so cache eviction can't erase it.
#' @param check When to run `checker()`: `"session"` (once per
#'   `keep_fresh()` call, i.e. once per package load), `"access"` (every
#'   access), or a number of seconds between checks.
#' @param snapshot Optional snapshot folder (see `$save_snapshot()`). If
#'   supplied, values are read from it instead of the checker and setters
#'   until `$use_snapshot(NULL)`.
#' @returns A `FreshHandle` R6 object (invisibly) with `key()` (the
#'   current version key), `refresh()` (re-run the checker now),
#'   `invalidate()` (re-run the checker on the next access), `reset()`
#'   (forget in-session values and checker state; the cache is untouched),
#'   `set_cache(cache)` (switch to another cachem cache; values already
#'   loaded this session are kept), `save_snapshot(dir, names, packages,
#'   key, metadata)` (write a hard copy of the values), `use_snapshot(dir,
#'   check_packages = TRUE)` (read values from a hard copy; `NULL` to stop),
#'   `cache` (the current cachem object), `state` (the state store), and
#'   `snapshot` (the snapshot in use, or `NULL`).
#' @examples
#' # Pretend the "current version" lives somewhere external.
#' current_version <- "v1"
#'
#' env <- new.env()
#' cache_dir <- tempfile("fresh-cache-")
#' handle <- keep_fresh(
#'   checker = function(state) current_version,
#'   setters = list(
#'     greeting = function(key) paste("Hello from", key)
#'   ),
#'   env = env,
#'   cache = cachem::cache_disk(cache_dir),
#'   check = "access"
#' )
#'
#' env$greeting
#'
#' # A new version is picked up on the next access.
#' current_version <- "v2"
#' env$greeting
#' handle$key()
#'
#' # The cache is an ordinary cachem object.
#' handle$cache$size()
#'
#' handle$cache$destroy()
#' @noRd
keep_fresh <- function(checker,
                       setters,
                       env,
                       cache = cachem::cache_mem(),
                       state = state_memory(),
                       check = "session",
                       snapshot = NULL) {
  stopifnot(
    is.function(checker),
    is.list(setters),
    rlang::is_named(setters),
    all(vapply(setters, is.function, logical(1))),
    is.environment(env)
  )
  .fresh_validate_cache(cache)
  .fresh_validate_state(state)
  check <- .fresh_validate_check(check)

  handle <- FreshHandle$new(checker, setters, cache, state, check)
  for (name in names(setters)) {
    makeActiveBinding(name, handle$binding(name), env)
  }
  if (!is.null(snapshot)) {
    handle$use_snapshot(snapshot)
  }
  invisible(handle)
}

FreshHandle <- R6::R6Class(
  "FreshHandle",
  public = list(
    initialize = function(checker, setters, cache, state, check) {
      private$checker <- checker
      private$setters <- setters
      private$names <- names(setters)
      private$cache_ <- cache
      private$state_ <- state
      private$check <- check
      private$values <- new.env(parent = emptyenv())
    },
    key = function() {
      private$key_
    },
    refresh = function() {
      private$checked_at <- NULL
      invisible(private$current_key())
    },
    invalidate = function() {
      private$checked_at <- NULL
      invisible(self)
    },
    reset = function() {
      private$key_ <- NULL
      private$checked_at <- NULL
      private$values <- new.env(parent = emptyenv())
      private$state_$reset()
      invisible(self)
    },
    set_cache = function(cache) {
      private$cache_ <- .fresh_validate_cache(cache)
      invisible(self)
    },
    # Returns the function used as the active binding for `name`.
    binding = function(name) {
      force(name)
      function(v) {
        if (!missing(v)) {
          cli::cli_abort("{.field {name}} is read-only.")
        }
        private$value_for(name)
      }
    },
    save_snapshot = function(dir,
                             names = NULL,
                             packages = NULL,
                             key = NULL,
                             metadata = NULL) {
      .fresh_save_snapshot(self, private, dir, names, packages, key, metadata)
    },
    use_snapshot = function(dir, check_packages = TRUE) {
      .fresh_use_snapshot(self, private, dir, check_packages)
    },
    print = function(...) {
      cli::cli_text("A fresh handle")
      cli::cli_bullets(c(
        "*" = "Current key: {.val {format(private$key_ %||% '(not checked yet)')}}",
        "*" = "Cache: {.cls {class(private$cache_)}}",
        "*" = "State: {.path {private$state_$path %||% '(in memory)'}}",
        "*" = "Snapshot: {.path {private$snapshot_$dir %||% '(none)'}}"
      ))
      invisible(self)
    }
  ),
  active = list(
    cache = function(value) {
      if (!missing(value)) {
        cli::cli_abort("Use {.code $set_cache()} to change the cache.")
      }
      private$cache_
    },
    state = function(value) {
      if (!missing(value)) {
        cli::cli_abort("{.field state} is read-only.")
      }
      private$state_
    },
    snapshot = function(value) {
      if (!missing(value)) {
        cli::cli_abort("Use {.code $use_snapshot()} to change the snapshot.")
      }
      private$snapshot_
    }
  ),
  private = list(
    checker = NULL,
    setters = NULL,
    snapshot_ = NULL,
    cache_ = NULL,
    state_ = NULL,
    check = NULL,
    key_ = NULL,
    checked_at = NULL,
    names = NULL,
    values = NULL,
    current_key = function() {
      if (.fresh_needs_check(private$checked_at, private$check)) {
        key <- private$checker(private$state_)
        if (!identical(key, private$key_)) {
          private$key_ <- key
          private$values <- new.env(parent = emptyenv())
        }
        private$checked_at <- Sys.time()
      }
      private$key_
    },
    value_for = function(name) {
      if (!is.null(private$snapshot_)) {
        if (!exists(name, envir = private$values, inherits = FALSE)) {
          value <- .snapshot_read_object(private$snapshot_, name)
          assign(name, value, envir = private$values)
        }
        return(get(name, envir = private$values, inherits = FALSE))
      }
      key <- private$current_key()
      if (exists(name, envir = private$values, inherits = FALSE)) {
        return(get(name, envir = private$values, inherits = FALSE))
      }
      setter <- private$setters[[name]]
      if (inherits(key, "fresh_uncached")) {
        value <- setter(key$key)
      } else {
        id <- .fresh_cache_id(key, name)
        cache <- private$cache_
        value <- cache$get(id)
        if (cachem::is.key_missing(value)) {
          value <- setter(key)
          cache$set(id, value)
        }
      }
      assign(name, value, envir = private$values)
      value
    }
  )
)

.fresh_validate_cache <- function(cache) {
  ok <- all(vapply(
    c("get", "set", "exists"),
    function(m) is.function(cache[[m]]),
    logical(1)
  ))
  if (!ok) {
    cli::cli_abort(
      "{.arg cache} must be a cachem cache, e.g. {.fn cachem::cache_disk}."
    )
  }
  invisible(cache)
}

.fresh_validate_state <- function(state) {
  ok <- all(vapply(
    c("get", "set", "reset"),
    function(m) is.function(state[[m]]),
    logical(1)
  ))
  if (!ok) {
    cli::cli_abort(
      "{.arg state} must be a state store, e.g. {.fn state_file}."
    )
  }
  invisible(state)
}

.fresh_validate_check <- function(check) {
  if (is.numeric(check) && length(check) == 1 && check >= 0) {
    return(check)
  }
  if (is.character(check) && length(check) == 1 &&
      check %in% c("session", "access")) {
    return(check)
  }
  cli::cli_abort(
    "{.arg check} must be {.val session}, {.val access}, or a number of seconds."
  )
}

.fresh_needs_check <- function(checked_at, check) {
  if (is.null(checked_at)) {
    return(TRUE)
  }
  if (identical(check, "session")) {
    return(FALSE)
  }
  if (identical(check, "access")) {
    return(TRUE)
  }
  difftime(Sys.time(), checked_at, units = "secs") >= check
}

#' Mark a version key as uncached
#'
#' Return `uncached(key)` from a `checker` when values for that version
#' shouldn't be stored in the cache, e.g. because they're read from local
#' files that are already on disk. Setters receive the plain `key`, and values
#' are still kept in memory for the session.
#'
#' @param key Version key.
#' @returns An object of class `fresh_uncached`.
#' @noRd
uncached <- function(key) {
  structure(list(key = key), class = "fresh_uncached")
}

# Exports ---------------------------------------------------------------------

#' NAMESPACE directives for fresh bindings
#'
#' Bindings created by `keep_fresh()` in `.onLoad` don't exist when roxygen2
#' scans the package, so `@export` can't see them. Use this with
#' `@evalNamespace` to export them from the same table that creates them:
#'
#' ```
#' #' @evalNamespace fresh_exports(names(my_setters))
#' NULL
#' ```
#'
#' Document each binding as a dataset with `@name`, `@docType data`, and an
#' explicit `@format`/`@usage`. Don't compute `@format` from the object
#' (e.g. `dim(x)`): that would trigger the setter during `document()`.
#'
#' @param names Character vector of binding names.
#' @returns Character vector of `export()` directives.
#' @noRd
fresh_exports <- function(names) {
  stopifnot(is.character(names))
  sprintf("export(%s)", names)
}

# Checker state ---------------------------------------------------------------
#
# Kept separate from the value cache because it's small, read every session,
# and must never be evicted. Anything with get(), set(), and reset() methods
# works as a state store; FreshState is a convenient base class.

#' Checker state stores
#'
#' `keep_fresh()` passes a state store to `checker` so it can remember things
#' between checks (e.g. what was installed last time, to skip a remote check).
#' `state_file()` persists state in a single RDS file; `state_memory()` keeps
#' it for the current session only.
#'
#' To store state elsewhere (e.g. a database), subclass `FreshState` and
#' override its private `load()` and `save()` methods, or supply any object
#' with `get(name, default = NULL)`, `set(name, value)`, and `reset()`
#' methods.
#'
#' @param path Path to the RDS file. Created on first write.
#' @returns An R6 object with `get(name, default = NULL)`, `set(name, value)`,
#'   `reset()`, and a read-only `path` (`NULL` for `state_memory()`).
#' @noRd
state_file <- function(path) {
  FreshStateFile$new(path)
}

#' @rdname state_file
#' @noRd
state_memory <- function() {
  FreshState$new()
}

FreshState <- R6::R6Class(
  "FreshState",
  public = list(
    get = function(name, default = NULL) {
      private$data()[[name]] %||% default
    },
    set = function(name, value) {
      data <- private$data()
      data[[name]] <- value
      private$memo <- data
      private$save(data)
      invisible(value)
    },
    reset = function() {
      private$memo <- list()
      private$clear()
      invisible(self)
    }
  ),
  active = list(
    path = function() NULL
  ),
  private = list(
    memo = NULL,
    data = function() {
      if (is.null(private$memo)) {
        private$memo <- private$load()
      }
      private$memo
    },
    # Backend hooks: in memory by default.
    load = function() list(),
    save = function(data) invisible(),
    clear = function() invisible()
  )
)

FreshStateFile <- R6::R6Class(
  "FreshStateFile",
  inherit = FreshState,
  public = list(
    initialize = function(path) {
      private$path_ <- path
    }
  ),
  active = list(
    path = function(value) {
      if (!missing(value)) {
        cli::cli_abort("{.field path} is read-only.")
      }
      private$path_
    }
  ),
  private = list(
    path_ = NULL,
    load = function() {
      if (file.exists(private$path_)) readRDS(private$path_) else list()
    },
    save = function(data) .fresh_write_rds(data, private$path_),
    clear = function() unlink(private$path_)
  )
)

# Values are stored in a cachem cache under a hash of (key, name), since
# cachem keys must be lowercase alphanumeric.
.fresh_cache_id <- function(key, name) {
  rlang::hash(list(key, name))
}

.fresh_write_json <- function(value, path) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  tmp <- tempfile(tmpdir = dirname(path), fileext = ".tmp")
  on.exit(unlink(tmp))
  jsonlite::write_json(value, tmp, auto_unbox = TRUE, pretty = TRUE, null = "null")
  .fresh_move(tmp, path)
}

# Write to a temp file next to the target, then rename, so concurrent readers
# never see a partial file.
.fresh_write_rds <- function(value, path) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  tmp <- tempfile(tmpdir = dirname(path), fileext = ".tmp")
  on.exit(unlink(tmp))
  saveRDS(value, tmp)
  .fresh_move(tmp, path)
}

.fresh_move <- function(from, to) {
  # file.rename() can't overwrite on Windows.
  if (file.exists(to)) {
    unlink(to)
  }
  if (!file.rename(from, to)) {
    file.copy(from, to, overwrite = TRUE)
  }
  invisible(to)
}
