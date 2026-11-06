# Handle for a set of fresh bindings

Created by
[`keep_fresh()`](https://gilead-public.github.io/gsm.core/dev/reference/keep_fresh.md).

## Active bindings

- `cache`:

  `cachem` The current cache (read-only; see `$set_cache()`).

- `state`:

  `FreshState` The checker's state store (read-only).

- `snapshot`:

  `list` The snapshot in use (see
  [`read_snapshot()`](https://gilead-public.github.io/gsm.core/dev/reference/read_snapshot.md)),
  or `NULL` (read-only).

## Methods

### Public methods

- [`FreshHandle$new()`](#method-FreshHandle-initialize)

- [`FreshHandle$key()`](#method-FreshHandle-key)

- [`FreshHandle$refresh()`](#method-FreshHandle-refresh)

- [`FreshHandle$invalidate()`](#method-FreshHandle-invalidate)

- [`FreshHandle$reset()`](#method-FreshHandle-reset)

- [`FreshHandle$set_cache()`](#method-FreshHandle-set_cache)

- [`FreshHandle$binding()`](#method-FreshHandle-binding)

- [`FreshHandle$save_snapshot()`](#method-FreshHandle-save_snapshot)

- [`FreshHandle$use_snapshot()`](#method-FreshHandle-use_snapshot)

- [`FreshHandle$print()`](#method-FreshHandle-print)

- [`FreshHandle$clone()`](#method-FreshHandle-clone)

------------------------------------------------------------------------

### `FreshHandle$new()`

Create a handle. Use
[`keep_fresh()`](https://gilead-public.github.io/gsm.core/dev/reference/keep_fresh.md)
instead.

#### Usage

    FreshHandle$new(checker, setters, cache, state, check, snapshot_names = NULL)

#### Arguments

- `checker, setters, check, snapshot_names`:

  See
  [`keep_fresh()`](https://gilead-public.github.io/gsm.core/dev/reference/keep_fresh.md).

- `cache`:

  `cachem` The current cache (read-only; see `$set_cache()`).

- `state`:

  `FreshState` See
  [`keep_fresh()`](https://gilead-public.github.io/gsm.core/dev/reference/keep_fresh.md).

------------------------------------------------------------------------

### `FreshHandle$key()`

The current version key.

#### Usage

    FreshHandle$key()

#### Returns

The key, or `NULL` if not checked yet.

------------------------------------------------------------------------

### `FreshHandle$refresh()`

Re-run the checker now.

#### Usage

    FreshHandle$refresh()

#### Returns

The current key, invisibly.

------------------------------------------------------------------------

### `FreshHandle$invalidate()`

Re-run the checker on the next access.

#### Usage

    FreshHandle$invalidate()

#### Returns

`FreshHandle` The handle, invisibly.

------------------------------------------------------------------------

### `FreshHandle$reset()`

Forget in-session values and checker state. The cache is untouched.

#### Usage

    FreshHandle$reset()

#### Returns

`FreshHandle` The handle, invisibly.

------------------------------------------------------------------------

### `FreshHandle$set_cache()`

Switch to another cache. Values already loaded this session are kept.

#### Usage

    FreshHandle$set_cache(cache)

#### Arguments

- `cache`:

  `cachem` A cachem cache (see
  [`keep_fresh()`](https://gilead-public.github.io/gsm.core/dev/reference/keep_fresh.md)).

#### Returns

`FreshHandle` The handle, invisibly.

------------------------------------------------------------------------

### `FreshHandle$binding()`

The function used as the active binding for `name`.

#### Usage

    FreshHandle$binding(name)

#### Arguments

- `name`:

  `character(1)` Binding name.

#### Returns

`function` An active binding function.

------------------------------------------------------------------------

### `FreshHandle$save_snapshot()`

Write a hard copy of the values to a snapshot folder.

#### Usage

    FreshHandle$save_snapshot(
      dir,
      names = NULL,
      packages = NULL,
      key = NULL,
      metadata = NULL
    )

#### Arguments

- `dir`:

  `character(1)` Snapshot folder to write.

- `names, packages, key, metadata`:

  See
  [`.fresh_save_snapshot()`](https://gilead-public.github.io/gsm.core/dev/reference/dot-fresh_save_snapshot.md).

#### Returns

`list` The snapshot description, invisibly.

------------------------------------------------------------------------

### `FreshHandle$use_snapshot()`

Read values from a snapshot folder instead of the checker and setters.

#### Usage

    FreshHandle$use_snapshot(dir, check_packages = TRUE)

#### Arguments

- `dir`:

  `character(1)` Snapshot folder to read, or `NULL` to stop.

- `check_packages`:

  `logical(1)` Tell the user if installed packages are newer than the
  snapshot's?

#### Returns

`FreshHandle` The handle, invisibly.

------------------------------------------------------------------------

### `FreshHandle$print()`

Print a summary of the handle.

#### Usage

    FreshHandle$print(...)

#### Arguments

- `...`:

  Unused.

#### Returns

`FreshHandle` The handle, invisibly.

------------------------------------------------------------------------

### `FreshHandle$clone()`

The objects of this class are cloneable with this method.

#### Usage

    FreshHandle$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.
