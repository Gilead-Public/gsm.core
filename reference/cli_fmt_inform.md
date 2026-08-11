# INFO-level cli dispatcher

Routes an INFO-level message to the appropriate `cli` formatting
function based on `cli_detail`. Called internally by
[`cli_fmt()`](https://gilead-biostats.github.io/gsm.core/reference/cli_fmt.md).

## Usage

``` r
cli_fmt_inform(message, cli_detail)
```

## Arguments

- message:

  Character string to display; may contain glue-style placeholders that
  are evaluated in `.envir`.

- cli_detail:

  For `level = "INFO"`, the cli style to use. Passed through to the
  active appender.

## Value

The return value of the dispatched `cli` function, invisibly.
