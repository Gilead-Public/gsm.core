# Build a setter that downloads and reads a file

Build a setter that downloads and reads a file

## Usage

``` r
download_setter(url, read = readRDS, checksum = NULL, request = NULL)
```

## Arguments

- url:

  `function` `function(key)` returning the URL for version `key`.

- read:

  `function` `function(path)` returning the value. Defaults to
  [`readRDS()`](https://rdrr.io/r/base/readRDS.html).

- checksum:

  `function` `function(key)` returning the expected sha256, or `NULL` to
  skip verification.

- request:

  `function` `function(url, dest)` that performs the download. Override
  for authentication, APIs, etc. `NULL` uses
  [`.fresh_default_request()`](https://gilead-public.github.io/gsm.core/dev/reference/dot-fresh_default_request.md).

## Value

`function` A `function(key)` suitable for `keep_fresh(setters = )`.
