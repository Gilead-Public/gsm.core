# Create the test data bindings and handle

Create the test data bindings and handle

## Usage

``` r
.register_testdata(
  env,
  cache = getOption("gsm.testdata_cache", .testdata_default_cache())
)
```

## Arguments

- env:

  `environment` Namespace to create the bindings in.

- cache:

  `cachem` Cache for downloaded values.

## Value

`FreshHandle` The handle (also stored as `gsm$testdata_handle`),
invisibly.
