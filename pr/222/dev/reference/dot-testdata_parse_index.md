# Validate and tidy the test data index

Validate and tidy the test data index

## Usage

``` r
.testdata_parse_index(index)
```

## Arguments

- index:

  `list` `index.json` read with
  `jsonlite::read_json(simplifyVector = TRUE)`.

## Value

`list` With `packages` (`character`), `fingerprints` (`list`), and
`builds` (`data.frame`, excluding `override` builds).
