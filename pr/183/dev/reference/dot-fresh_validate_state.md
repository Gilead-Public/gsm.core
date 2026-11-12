# Check that an object works as a state store

Check that an object works as a state store

## Usage

``` r
.fresh_validate_state(state)
```

## Arguments

- state:

  `FreshState` Where `checker` keeps its state:
  [`state_memory()`](https://gilead-public.github.io/gsm.core/dev/reference/state_file.md)
  (the default) or
  [`state_file()`](https://gilead-public.github.io/gsm.core/dev/reference/state_file.md)
  to persist it across sessions. Kept separate from `cache` so cache
  eviction can't erase it.

## Value

`FreshState` `state`, invisibly. Errors if it lacks
[`get()`](https://rdrr.io/r/base/get.html), `set()`, or `reset()`.
