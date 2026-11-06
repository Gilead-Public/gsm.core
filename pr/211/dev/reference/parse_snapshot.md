# Validate a parsed snapshot.json

Validate a parsed snapshot.json

## Usage

``` r
parse_snapshot(info, source = "snapshot.json")
```

## Arguments

- info:

  `list` `snapshot.json` parsed with
  [`jsonlite::read_json()`](https://jeroen.r-universe.dev/jsonlite/reference/read_json.html).

- source:

  `character(1)` Where it came from, for error messages.

## Value

`list` `info`, unchanged.
