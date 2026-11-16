# Build a setter that downloads and reads a file

Build a setter that downloads and reads a file

## Usage

``` r
construct_fetcher(
  url_constructor,
  reader = readRDS,
  checksum_finder = NULL,
  digest_finder = NULL,
  downloader = fetch_binary
)
```

## Arguments

- url_constructor:

  `function` `function(key)` returning the URL for version `key`.

- reader:

  `function` `function(path)` returning the value. Defaults to
  [`readRDS()`](https://rdrr.io/r/base/readRDS.html).

- checksum_finder:

  `function` `function(key)` returning the expected sha256 of the
  downloaded file for version `key`, or `NULL` to skip verification.

- digest_finder:

  `function` `function(key)` returning the expected
  [`fresh_digest()`](https://gilead-public.github.io/gsm.core/dev/reference/fresh_digest.md)
  of the value `reader` returns for version `key`, or `NULL` to skip
  verification.

- downloader:

  `function` `function(url, dest)` that downloads `url` to `dest` and
  errors on failure. Override for authentication, APIs, etc.

## Value

`function` A `function(key)` suitable for `keep_fresh(setters = )`.
