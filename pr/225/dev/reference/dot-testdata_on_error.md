# Turn a failed test data read into a warning

Test data is a development convenience, so a failure shouldn't stop work
(or package installation, which reads every binding).

## Usage

``` r
.testdata_on_error(cnd, name)
```

## Arguments

- cnd:

  `condition` The error.

- name:

  `character(1)` The binding name.

## Value

`NULL`, with a `gsm_testdata_unavailable` warning (a silent condition of
the same class in R CMD INSTALL/check, so it can't add warnings to their
logs).
