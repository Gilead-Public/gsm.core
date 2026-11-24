# Checker state saved in an RDS file

Create one with
[`state_file()`](https://gilead-public.github.io/gsm.core/dev/reference/state_file.md).

## Super class

[`FreshState`](https://gilead-public.github.io/gsm.core/dev/reference/FreshState.md)
-\> `FreshStateFile`

## Active bindings

- `path`:

  `character(1)` Path to the RDS file (read-only).

## Methods

### Public methods

- [`FreshStateFile$new()`](#method-FreshStateFile-initialize)

- [`FreshStateFile$clone()`](#method-FreshStateFile-clone)

Inherited methods

- [`FreshState$get()`](https://gilead-public.github.io/gsm.core/dev/reference/FreshState.html#method-get)
- [`FreshState$reset()`](https://gilead-public.github.io/gsm.core/dev/reference/FreshState.html#method-reset)
- [`FreshState$set()`](https://gilead-public.github.io/gsm.core/dev/reference/FreshState.html#method-set)

------------------------------------------------------------------------

### `FreshStateFile$new()`

Create a store. Use
[`state_file()`](https://gilead-public.github.io/gsm.core/dev/reference/state_file.md)
instead.

#### Usage

    FreshStateFile$new(path)

#### Arguments

- `path`:

  `character(1)` or `function` See
  [`state_file()`](https://gilead-public.github.io/gsm.core/dev/reference/state_file.md).

------------------------------------------------------------------------

### `FreshStateFile$clone()`

The objects of this class are cloneable with this method.

#### Usage

    FreshStateFile$clone(deep = FALSE)

#### Arguments

- `deep`:

  Whether to make a deep clone.
