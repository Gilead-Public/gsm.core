# Log a message via the active appender

Emits a log message at the specified level, provided the level meets or
exceeds the current log threshold. The message is glue-interpolated
before being passed to the active appender.

## Usage

``` r
LogMessage(level, message, cli_detail = NULL, .envir = parent.frame())
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

- .envir:

  Environment in which to evaluate glue expressions. Defaults to the
  caller's environment.

## Value

`NULL`, invisibly.
