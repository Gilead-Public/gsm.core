# cli-style console appender for gsm

Dispatches a log message to the appropriate `cli` function based on
`level`. Used as the default log appender.

## Usage

``` r
cli_fmt(level, message, cli_detail = NULL)
```

## Arguments

- level:

  Log level: `"INFO"`, `"WARN"`, `"ERROR"`, or `"FATAL"`.
  Case-insensitive.

- message:

  Character string to display; may contain glue-style placeholders that
  are evaluated in `.envir`.

- cli_detail:

  For `level = "INFO"`, the cli style to use. Passed through to the
  active appender.

## Value

`NULL`, invisibly.
