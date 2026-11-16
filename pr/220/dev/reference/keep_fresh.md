# Bind objects into an environment and keep them fresh

Makes objects that look like ordinary variables but always hold an
up-to-date value, built only when it's first needed. Use it for data
that lives elsewhere (e.g. a download) and changes occasionally: users
keep writing `pkg::my_data` and get the current version without calling
a function.

## Usage

``` r
keep_fresh(
  checker,
  setters,
  env,
  cache = cachem::cache_mem(),
  state = state_memory(),
  check = "session",
  snapshot_path = NULL,
  snapshot_names = NULL
)
```

## Arguments

- checker:

  `function` `function(state)` returning a version key (any R object,
  compared with [`identical()`](https://rdrr.io/r/base/identical.html)).
  `state` is the `state` store, so the checker can remember things
  between checks (e.g. to skip expensive remote checks).

- setters:

  `list` Named list of `function(key)`, each returning the value for
  that name at version `key`.

- env:

  `environment` Environment (or unlocked namespace) to create the
  bindings in.

- cache:

  `cachem` A cachem cache, such as
  [`cachem::cache_mem()`](https://cachem.r-lib.org/reference/cache_mem.html)
  (the default; values last for the session) or
  [`cachem::cache_disk()`](https://cachem.r-lib.org/reference/cache_disk.html)
  (values persist across sessions). Any object with
  [`get()`](https://rdrr.io/r/base/get.html), `set()`, and
  [`exists()`](https://rdrr.io/r/base/exists.html) methods in the cachem
  style works.

- state:

  `FreshState` Where `checker` keeps its state:
  [`state_memory()`](https://gilead-public.github.io/gsm.core/dev/reference/state_file.md)
  (the default) or
  [`state_file()`](https://gilead-public.github.io/gsm.core/dev/reference/state_file.md)
  to persist it across sessions. Kept separate from `cache` so cache
  eviction can't erase it.

- check:

  `character(1)` or `numeric(1)` When to run `checker()`: `"session"`
  (once per `keep_fresh()` call, i.e. once per package load), `"access"`
  (every access), or a number of seconds between checks.

- snapshot_path:

  `character(1)` Optional snapshot folder (see `$save_snapshot()`). If
  supplied, values are read from it instead of the checker and setters
  until `$use_snapshot(NULL)`.

- snapshot_names:

  `character` Named vector mapping binding names to object names in
  snapshots, for bindings whose snapshot object has a different name.
  Unlisted bindings use their own name.

## Value

`FreshHandle` An R6 object (invisibly) with `key()` (the current version
key), `refresh()` (re-run the checker now), `invalidate()` (re-run the
checker on the next access), `reset()` (forget in-session values and
checker state; the cache is untouched), `set_cache(cache)` (switch to
another cachem cache; values already loaded this session are kept),
`save_snapshot(dir, names, packages, key, metadata)` (write a hard copy
of the values), `use_snapshot(dir, check_packages = TRUE)` (read values
from a hard copy; `NULL` to stop), `cache` (the current cachem object),
`state` (the state store), and `snapshot` (the snapshot in use, or
`NULL`).

## Details

Supply a `checker` that reports which version of the data is current,
and one `setter` per object that builds that object for a given version.
Call `keep_fresh()` from your package's `.onLoad()` with `env` set to
the package namespace, and export the objects with
[`fresh_exports()`](https://gilead-public.github.io/gsm.core/dev/reference/fresh_exports.md).
Values are stored in `cache`, so a setter only runs again when `checker`
reports a new version.

The cache is a standard cachem object, so you (and your users) can
choose its location, size limits, and age limits, inspect it, or prune
it with the usual cachem methods. Packages that use `keep_fresh()`
should let users supply their own cache (e.g. via an option) and expose
the handle's `cache` so it's never hidden.
