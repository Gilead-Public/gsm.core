# Download a file in binary mode, erroring on failure

A wrapper around
[`utils::download.file()`](https://rdrr.io/r/utils/download.file.html)
with `mode = "wb"` and `quiet = TRUE` that errors on a non-zero status
instead of returning it.

## Usage

``` r
fetch_binary(url, dest)
```

## Arguments

- url:

  `character(1)` URL to download.

- dest:

  `character(1)` Destination path.

## Value

`dest`, invisibly.
