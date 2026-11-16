# Checker state kept in memory

Base class for state stores. Create one with
[`state_memory()`](https://gilead-public.github.io/gsm.core/dev/reference/state_file.md).
Subclasses override the private
[`load()`](https://rdrr.io/r/base/load.html),
[`save()`](https://rdrr.io/r/base/save.html), and `clear()` methods.

## Active bindings

- `path`:

  `NULL`, since state isn't saved anywhere.

## Methods

### Public methods

- [`FreshState$get()`](#method-FreshState-get)

- [`FreshState$set()`](#method-FreshState-set)

- [`FreshState$reset()`](#method-FreshState-reset)

- [`FreshState$clone()`](#method-FreshState-clone)

------------------------------------------------------------------------

### `FreshState$get()`

Get a state entry.

#### Usage

    FreshState$get(name, default = NULL)

#### Arguments

- `name`:

  `character(1)` Entry name.

- `default`:

  Value to return if the entry is unset.

#### Returns

The entry's value, or `default`.

------------------------------------------------------------------------

### `FreshState$set()`

Set a state entry.

#### Usage

    FreshState$set(name, value)

#### Arguments

- `name`:

  `character(1)` Entry name.

- `value`:

  Value to store.

#### Returns

`value`, invisibly.

------------------------------------------------------------------------

### `FreshState$reset()`

Remove all state entries.

#### Usage

    FreshState$reset()

#### Returns

The store, invisibly.

------------------------------------------------------------------------

### `FreshState$clone()`

The objects of this class are cloneable with this method.

#### Usage

    FreshState$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.
