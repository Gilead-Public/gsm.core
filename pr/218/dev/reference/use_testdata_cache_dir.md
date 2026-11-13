# Choose where the test data is cached

**\[experimental\]**

## Usage

``` r
use_testdata_cache_dir(dir)
```

## Arguments

- dir:

  `character(1)` Directory for the disk cache, created if needed. Also
  accepts `NULL` (unset the option, returning to the default cache) or a
  value previously returned by this function, to restore it.

## Value

`cachem` The previous value of the `gsm.testdata_cache` option,
invisibly, so it can be restored with `use_testdata_cache_dir(old)`.

## Details

The test data objects (e.g.
[lSource](https://gilead-public.github.io/gsm.core/dev/reference/lSource.md))
are cached in a cachem cache after they're first downloaded.
`use_testdata_cache_dir()` caches them on disk in `dir`, by setting the
`gsm.testdata_cache` option to `cachem::cache_disk(dir)` and switching
the current session to it.

If the option is unset, gsm.core uses
[`cachem::cache_disk()`](https://cachem.r-lib.org/reference/cache_disk.html)
in `tools::R_user_dir("gsm", "cache")` (set `R_USER_CACHE_DIR` to move
it), with cachem's default size limit and no age limit.

Any cachem cache works. For other cachem mechanisms or settings, such as
an in-memory cache or size and age limits, set the option yourself, e.g.
in your `.Rprofile` so it applies every session:

    options(gsm.testdata_cache = cachem::cache_disk(
      "~/gsm-cache", max_size = 512 * 1024^2, max_age = 60 * 60 * 24 * 30
    ))
    options(gsm.testdata_cache = cachem::cache_mem())

In a running session, `gsm_testdata(cache = )` switches to any cachem
cache and sets the option.

## See also

[`gsm_testdata()`](https://gilead-public.github.io/gsm.core/dev/reference/gsm_testdata.md)
to inspect or clear the cache.

## Examples

``` r
old <- use_testdata_cache_dir(file.path(tempdir(), "gsm-cache"))
gsm_testdata()$cache$info()$dir
#> [1] "/tmp/Rtmp1CPUKu/gsm-cache"
use_testdata_cache_dir(old)
```
