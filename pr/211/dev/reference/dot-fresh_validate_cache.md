# Check that an object works as a cachem cache

Check that an object works as a cachem cache

## Usage

``` r
.fresh_validate_cache(cache)
```

## Arguments

- cache:

  `cachem` A cachem cache, such as
  [`cachem::cache_mem()`](https://cachem.r-lib.org/reference/cache_mem.html)
  (the default; values last for the session) or
  [`cachem::cache_disk()`](https://cachem.r-lib.org/reference/cache_disk.html)
  (values persist across sessions). Any object with
  [`get()`](https://rdrr.io/r/base/get.html), `set()`, and
  [`exists()`](https://rdrr.io/r/base/exists.html) methods in the cachem
  style works.

## Value

`cachem` `cache`, invisibly. Errors if it lacks
[`get()`](https://rdrr.io/r/base/get.html), `set()`, or
[`exists()`](https://rdrr.io/r/base/exists.html).
