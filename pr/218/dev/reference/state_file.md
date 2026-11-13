# Checker state stores

[`keep_fresh()`](https://gilead-public.github.io/gsm.core/dev/reference/keep_fresh.md)
passes a state store to `checker` so it can remember things between
checks (e.g. what was installed last time, to skip a remote check).
`state_file()` persists state in a single RDS file; `state_memory()`
keeps it for the current session only.

## Usage

``` r
state_file(path)

state_memory()
```

## Arguments

- path:

  `character(1)` or `function` Path to the RDS file, or a function
  returning it (evaluated on each read and write, so the location can
  follow e.g. an environment variable). Created on first write.

## Value

`FreshState` An R6 object with `get(name, default = NULL)`,
`set(name, value)`, `reset()`, and a read-only `path` (`NULL` for
`state_memory()`).

## Details

To store state elsewhere (e.g. a database), subclass `FreshState` and
override its private [`load()`](https://rdrr.io/r/base/load.html) and
[`save()`](https://rdrr.io/r/base/save.html) methods, or supply any
object with `get(name, default = NULL)`, `set(name, value)`, and
`reset()` methods.
