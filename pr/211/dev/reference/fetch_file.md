# Download a file, optionally verifying a sha256 checksum

Download a file, optionally verifying a sha256 checksum

## Usage

``` r
fetch_file(url, dest, checksum = NULL, request = NULL)
```

## Arguments

- url:

  `character(1)` URL to download.

- dest:

  `character(1)` Destination path. Written atomically.

- checksum:

  `character(1)` Expected sha256 (hex), or `NULL` to skip verification.

- request:

  `function` `function(url, dest)` that performs the download. Override
  for authentication, APIs, etc. `NULL` uses
  [`.fresh_default_request()`](https://gilead-public.github.io/gsm.core/dev/reference/dot-fresh_default_request.md).

## Value

`dest`, invisibly.
