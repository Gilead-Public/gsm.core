# Inspect and manage the cached test data

**\[experimental\]**

## Usage

``` r
gsm_testdata(cache = getOption("gsm.testdata_cache"))
```

## Arguments

- cache:

  `cachem` A cachem cache to use from now on. Defaults to the
  `gsm.testdata_cache` option; `NULL` keeps the current cache. A new
  cache is also stored in that option for the rest of the session.
  Objects already loaded this session stay in memory; later loads use
  the new cache.

## Value

`FreshHandle` An R6 object with

- `key()`: the release tag currently in use.

- `refresh()`: choose the release again now.

- `reset()`: forget the release choice, so the next access re-resolves
  everything. Cached values are kept.

- `set_cache(cache)`: switch caches without changing the option.

- `cache`: the current cachem object. Use its methods directly, e.g.
  `gsm_testdata()$cache$size()`, `$keys()`, `$prune()`, `$reset()`
  (delete all cached values), or `$destroy()`.

- `state`: the store that records the chosen release; `state$path` shows
  where it's saved.

- `snapshot`: the local folder in use (see
  [`use_testdata_snapshot()`](https://gilead-public.github.io/gsm.core/dev/reference/use_testdata_snapshot.md)),
  or `NULL`.

## Details

The test data objects (e.g.
[analyticsInput](https://gilead-public.github.io/gsm.core/dev/reference/analyticsInput.md))
are cached in a standard cachem cache. `gsm_testdata()` returns a handle
for inspecting and managing it, and can switch to a different cache.

To change where or how values are cached, see
[`use_testdata_cache_dir()`](https://gilead-public.github.io/gsm.core/dev/reference/use_testdata_cache_dir.md).

## Examples

``` r
handle <- gsm_testdata()
handle
#> A fresh handle
#> • Current key: "data-8cde53949d4d"
#> • Cache: <cache_disk/cachem>
#> • State: /home/runner/.cache/R/gsm/testdata-state.rds
#> • Snapshot: '(none)'
handle$cache$info()
#> $dir
#> [1] "/home/runner/.cache/R/gsm/values"
#> 
#> $max_size
#> [1] 1073741824
#> 
#> $max_age
#> [1] Inf
#> 
#> $max_n
#> [1] Inf
#> 
#> $evict
#> [1] "lru"
#> 
#> $destroy_on_finalize
#> [1] FALSE
#> 
#> $missing
#> <quosure>
#> expr: ^key_missing()
#> env:  0x55e1ad20e8b0
#> 
#> $prune_rate
#> [1] 20
#> 
#> $logfile
#> NULL
#> 
#> $prune_throttle_counter
#> [1] 0
#> 
#> $prune_last_time
#> [1] "2026-11-09 16:48:31 UTC"
#> 

# Switch to a temporary in-memory cache, then back.
old <- handle$cache
gsm_testdata(cache = cachem::cache_mem())
#> A fresh handle
#> • Current key: "data-8cde53949d4d"
#> • Cache: <cache_mem/cachem>
#> • State: /home/runner/.cache/R/gsm/testdata-state.rds
#> • Snapshot: '(none)'
gsm_testdata(cache = old)
#> A fresh handle
#> • Current key: "data-8cde53949d4d"
#> • Cache: <cache_disk/cachem>
#> • State: /home/runner/.cache/R/gsm/testdata-state.rds
#> • Snapshot: '(none)'
```
