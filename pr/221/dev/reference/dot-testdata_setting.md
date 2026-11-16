# Read and validate a test data setting

Read and validate a test data setting

## Usage

``` r
.testdata_setting(name, pattern = NULL)
```

## Arguments

- name:

  `character(1)` `"testdata_dir"` or `"testdata_tag"`.

- pattern:

  `character(1)` Optional regex the value must match.

## Value

`character(1)` The value, or `NULL` if unset (`NULL` or `""`). Validated
here, on use, so bad environment variables can't break package loading.
