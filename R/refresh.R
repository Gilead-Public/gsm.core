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
#' @param checker `function` `function(state)` returning a version key (any R
#'   object, compared with [identical()]). `state` is the `state` store, so the
#'   checker can remember things between checks (e.g. to skip expensive remote
#'   checks).
#' @param setters `list` Named list of `function(key)`, each returning the
#'   value for that name at version `key`.
#' @param env `environment` Environment (or unlocked namespace) to create the
#'   bindings in.
#' @param cache `cachem` A \pkg{cachem} cache, such as [cachem::cache_mem()]
#'   (the default; values last for the session) or [cachem::cache_disk()]
#'   (values persist across sessions). Any object with `get()`, `set()`, and
#'   `exists()` methods in the cachem style works.
#' @param state `FreshState` Where `checker` keeps its state: `state_memory()`
#'   (the default) or `state_file()` to persist it across sessions. Kept
#'   separate from `cache` so cache eviction can't erase it.
#' @param check `character(1)` or `numeric(1)` When to run `checker()`:
#'   `"session"` (once per `keep_fresh()` call, i.e. once per package load),
#'   `"access"` (every access), or a number of seconds between checks.
#' @param snapshot_path `character(1)` Optional snapshot folder (see
#'   `$save_snapshot()`). If supplied, values are read from it instead of the
#'   checker and setters until `$use_snapshot(NULL)`.
#' @param snapshot_names `character` Named vector mapping binding names to
#'   object names in snapshots, for bindings whose snapshot object has a
#'   different name. Unlisted bindings use their own name.
#' @returns `FreshHandle` An R6 object (invisibly) with `key()` (the
#'   current version key), `refresh()` (re-run the checker now),
#'   `invalidate()` (re-run the checker on the next access), `reset()`
#'   (forget in-session values and checker state; the cache is untouched),
#'   `set_cache(cache)` (switch to another cachem cache; values already
#'   loaded this session are kept), `save_snapshot(dir, names, packages,
#'   key, metadata)` (write a hard copy of the values), `use_snapshot(dir,
#'   check_packages = TRUE)` (read values from a hard copy; `NULL` to stop),
#'   `cache` (the current cachem object), `state` (the state store), and
#'   `snapshot` (the snapshot in use, or `NULL`).
#' @keywords internal
keep_fresh <- function(
  checker,
  setters,
  env,
  cache = cachem::cache_mem(),
  state = state_memory(),
  check = "session",
  snapshot_path = NULL,
  snapshot_names = NULL
) {
  stopifnot(
    is.function(checker),
    is.list(setters),
    rlang::is_named(setters),
    all(vapply(setters, is.function, logical(1))),
    is.environment(env),
    is.null(snapshot_names) ||
      (is.character(snapshot_names) && rlang::is_named(snapshot_names))
  )
  .fresh_validate_cache(cache)
  .fresh_validate_state(state)
  check <- .fresh_validate_check(check)

  handle <- FreshHandle$new(
    checker,
    setters,
    cache,
    state,
    check,
    snapshot_names
  )
  for (name in names(setters)) {
    makeActiveBinding(name, handle$binding(name), env)
  }
  if (!is.null(snapshot_path)) {
    handle$use_snapshot(snapshot_path)
  }
  invisible(handle)
}

#' Handle for a set of fresh bindings
#'
#' Created by [keep_fresh()].
#'
#' @keywords internal
FreshHandle <- R6::R6Class(
  "FreshHandle",
  public = list(
    #' @description Create a handle. Use [keep_fresh()] instead.
    #' @param checker,setters,check,snapshot_names See [keep_fresh()].
    #' @param state `FreshState` See [keep_fresh()].
    initialize = function(
      checker,
      setters,
      cache,
      state,
      check,
      snapshot_names = NULL
    ) {
      private$checker <- checker
      private$setters <- setters
      private$names <- names(setters)
      private$snapshot_names <- rlang::set_names(private$names)
      private$snapshot_names[names(snapshot_names)] <- snapshot_names
      private$cache_ <- cache
      private$state_ <- state
      private$check <- check
      private$values <- new.env(parent = emptyenv())
    },
    #' @description The current version key.
    #' @returns The key, or `NULL` if not checked yet.
    key = function() {
      private$key_
    },
    #' @description Re-run the checker now.
    #' @returns The current key, invisibly.
    refresh = function() {
      private$checked_at <- NULL
      invisible(private$current_key())
    },
    #' @description Re-run the checker on the next access.
    #' @returns `FreshHandle` The handle, invisibly.
    invalidate = function() {
      private$checked_at <- NULL
      invisible(self)
    },
    #' @description Forget in-session values and checker state. The cache is
    #'   untouched.
    #' @returns `FreshHandle` The handle, invisibly.
    reset = function() {
      private$key_ <- NULL
      private$checked_at <- NULL
      private$values <- new.env(parent = emptyenv())
      private$state_$reset()
      invisible(self)
    },
    #' @description Switch to another cache. Values already loaded this
    #'   session are kept.
    #' @param cache `cachem` A \pkg{cachem} cache (see [keep_fresh()]).
    #' @returns `FreshHandle` The handle, invisibly.
    set_cache = function(cache) {
      private$cache_ <- .fresh_validate_cache(cache)
      invisible(self)
    },
    #' @description The function used as the active binding for `name`.
    #' @param name `character(1)` Binding name.
    #' @returns `function` An active binding function.
    binding = function(name) {
      force(name)
      function(v) {
        if (!missing(v)) {
          cli::cli_abort("{.field {name}} is read-only.")
        }
        private$value_for(name)
      }
    },
    #' @description Write a hard copy of the values to a snapshot folder.
    #' @param dir `character(1)` Snapshot folder to write.
    #' @param names,packages,key,metadata See [.fresh_save_snapshot()].
    #' @returns `list` The snapshot description, invisibly.
    save_snapshot = function(
      dir,
      names = NULL,
      packages = NULL,
      key = NULL,
      metadata = NULL
    ) {
      .fresh_save_snapshot(self, private, dir, names, packages, key, metadata)
    },
    #' @description Read values from a snapshot folder instead of the checker
    #'   and setters.
    #' @param dir `character(1)` Snapshot folder to read, or `NULL` to stop.
    #' @param check_packages `logical(1)` Tell the user if installed packages
    #'   are newer than the snapshot's?
    #' @returns `FreshHandle` The handle, invisibly.
    use_snapshot = function(dir, check_packages = TRUE) {
      .fresh_use_snapshot(self, private, dir, check_packages)
    },
    #' @description Print a summary of the handle.
    #' @param ... Unused.
    #' @returns `FreshHandle` The handle, invisibly.
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
    #' @field cache `cachem` The current cache (read-only; see `$set_cache()`).
    cache = function(value) {
      if (!missing(value)) {
        cli::cli_abort("Use {.code $set_cache()} to change the cache.")
      }
      private$cache_
    },
    #' @field state `FreshState` The checker's state store (read-only).
    state = function(value) {
      if (!missing(value)) {
        cli::cli_abort("{.field state} is read-only.")
      }
      private$state_
    },
    #' @field snapshot `list` The snapshot in use (see [read_snapshot()]), or
    #'   `NULL` (read-only).
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
    snapshot_names = NULL,
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
          value <- .snapshot_read_object(
            private$snapshot_,
            private$snapshot_names[[name]]
          )
          assign(name, value, envir = private$values)
        }
        return(get(name, envir = private$values, inherits = FALSE))
      }
      key <- private$current_key()
      if (exists(name, envir = private$values, inherits = FALSE)) {
        return(get(name, envir = private$values, inherits = FALSE))
      }
      id <- .fresh_cache_id(key, name)
      cache <- private$cache_
      value <- cache$get(id)
      if (cachem::is.key_missing(value)) {
        value <- private$setters[[name]](key)
        cache$set(id, value)
      }
      assign(name, value, envir = private$values)
      value
    }
  )
)

#' Check that an object works as a cachem cache
#'
#' @inheritParams keep_fresh
#' @returns `cachem` `cache`, invisibly. Errors if it lacks `get()`, `set()`,
#'   or `exists()`.
#' @keywords internal
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

#' Check that an object works as a state store
#'
#' @inheritParams keep_fresh
#' @returns `FreshState` `state`, invisibly. Errors if it lacks `get()`,
#'   `set()`, or `reset()`.
#' @keywords internal
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

#' Check a `keep_fresh(check = )` value
#'
#' @inheritParams keep_fresh
#' @returns `character(1)` or `numeric(1)` `check`, if valid.
#' @keywords internal
.fresh_validate_check <- function(check) {
  if (is.numeric(check) && length(check) == 1 && check >= 0) {
    return(check)
  }
  if (
    is.character(check) &&
      length(check) == 1 &&
      check %in% c("session", "access")
  ) {
    return(check)
  }
  cli::cli_abort(
    "{.arg check} must be {.val session}, {.val access}, or a number of seconds."
  )
}

#' Is it time to run the checker again?
#'
#' @param checked_at `POSIXct` When the checker last ran, or `NULL` if never.
#' @inheritParams keep_fresh
#' @returns `logical(1)`.
#' @keywords internal
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
#' @param names `character` Binding names.
#' @returns `character` `export()` directives.
#' @keywords internal
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
#' @param path `character(1)` or `function` Path to the RDS file, or a
#'   function returning it (evaluated on each read and write, so the location
#'   can follow e.g. an environment variable). Created on first write.
#' @returns `FreshState` An R6 object with `get(name, default = NULL)`,
#'   `set(name, value)`, `reset()`, and a read-only `path` (`NULL` for
#'   `state_memory()`).
#' @keywords internal
state_file <- function(path) {
  FreshStateFile$new(path)
}

#' @rdname state_file
state_memory <- function() {
  FreshState$new()
}

#' Checker state kept in memory
#'
#' Base class for state stores. Create one with [state_memory()]. Subclasses
#' override the private `load()`, `save()`, and `clear()` methods.
#'
#' @keywords internal
FreshState <- R6::R6Class(
  "FreshState",
  public = list(
    #' @description Get a state entry.
    #' @param name `character(1)` Entry name.
    #' @param default Value to return if the entry is unset.
    #' @returns The entry's value, or `default`.
    get = function(name, default = NULL) {
      private$data()[[name]] %||% default
    },
    #' @description Set a state entry.
    #' @param name `character(1)` Entry name.
    #' @param value Value to store.
    #' @returns `value`, invisibly.
    set = function(name, value) {
      data <- private$data()
      data[[name]] <- value
      private$memo <- data
      private$save(data)
      invisible(value)
    },
    #' @description Remove all state entries.
    #' @returns The store, invisibly.
    reset = function() {
      private$memo <- list()
      private$clear()
      invisible(self)
    }
  ),
  active = list(
    #' @field path `NULL`, since state isn't saved anywhere.
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

#' Checker state saved in an RDS file
#'
#' Create one with [state_file()].
#'
#' @keywords internal
FreshStateFile <- R6::R6Class(
  "FreshStateFile",
  inherit = FreshState,
  public = list(
    #' @description Create a store. Use [state_file()] instead.
    #' @param path `character(1)` or `function` See [state_file()].
    initialize = function(path) {
      private$path_ <- path
    }
  ),
  active = list(
    #' @field path `character(1)` Path to the RDS file (read-only).
    path = function(value) {
      if (!missing(value)) {
        cli::cli_abort("{.field path} is read-only.")
      }
      if (is.function(private$path_)) private$path_() else private$path_
    }
  ),
  private = list(
    path_ = NULL,
    load = function() {
      if (file.exists(self$path)) readRDS(self$path) else list()
    },
    save = function(data) .fresh_write_rds(data, self$path),
    clear = function() unlink(self$path)
  )
)

#' Cache id for one value
#'
#' @param key The version key from the checker.
#' @param name `character(1)` Binding name.
#' @returns `character(1)` A hash of `key` and `name` (cachem keys must be
#'   lowercase alphanumeric).
#' @keywords internal
.fresh_cache_id <- function(key, name) {
  rlang::hash(list(key, name))
}

#' Write JSON atomically
#'
#' @param value `list` Value to write.
#' @param path `character(1)` Destination path. Parent folders are created.
#' @returns `character(1)` `path`, invisibly.
#' @keywords internal
.fresh_write_json <- function(value, path) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  tmp <- tempfile(tmpdir = dirname(path), fileext = ".tmp")
  on.exit(unlink(tmp))
  jsonlite::write_json(
    value,
    tmp,
    auto_unbox = TRUE,
    pretty = TRUE,
    null = "null",
    digits = NA
  )
  .fresh_move(tmp, path)
}

#' Write an RDS file atomically
#'
#' @param value Value to write.
#' @inheritParams .fresh_write_json
#' @returns `character(1)` `path`, invisibly.
#' @keywords internal
.fresh_write_rds <- function(value, path) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  tmp <- tempfile(tmpdir = dirname(path), fileext = ".tmp")
  on.exit(unlink(tmp))
  saveRDS(value, tmp)
  .fresh_move(tmp, path)
}

#' Move a file, replacing the destination
#'
#' @param from `character(1)` Source path.
#' @param to `character(1)` Destination path.
#' @returns `character(1)` `to`, invisibly. Errors on failure.
#' @keywords internal
.fresh_move <- function(from, to) {
  # file.rename() can't overwrite on Windows.
  if (file.exists(to)) {
    unlink(to)
  }
  if (!file.rename(from, to) && !file.copy(from, to, overwrite = TRUE)) {
    stop("Failed to write ", to, call. = FALSE)
  }
  invisible(to)
}
