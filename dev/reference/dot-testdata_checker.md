# Choose the test data release to use

Choose the test data release to use

## Usage

``` r
.testdata_checker(state)
```

## Arguments

- state:

  `FreshState` The handle's state store; the `"lookup"` entry records
  the last choice.

## Value

`character(1)` The release tag. A tag holds exactly one data
fingerprint, so caching values by tag also caches them by fingerprint.
