# Download a file, optionally verifying a sha256 checksum

Download a file, optionally verifying a sha256 checksum

## Usage

``` r
safely_fetch(url, dest, checksum = NULL, downloader = fetch_binary)
```

## Arguments

- url:

  `character(1)` URL to download.

- dest:

  `character(1)` Destination path. Written atomically.

- checksum:

  `character(1)` Expected sha256 (hex), or `NULL` to skip verification.

- downloader:

  `function` `function(url, dest)` that downloads `url` to `dest` and
  errors on failure. Override for authentication, APIs, etc.

## Value

`dest`, invisibly.
