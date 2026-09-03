# Set the active log level

Validates `level` and sets `.le$log_level`. Called internally by
[`SetLogger()`](https://gilead-public.github.io/gsm.core/dev/reference/SetLogger.md)
methods and may be called directly when only the level (not a logger
object) needs to change.

## Usage

``` r
SetLogLevel(level)

# S3 method for class 'character'
SetLogLevel(level)

# S3 method for class 'loglevel'
SetLogLevel(level)

# S3 method for class 'numeric'
SetLogLevel(level)

# Default S3 method
SetLogLevel(level)
```

## Arguments

- level:

  A character string (one of `"DEBUG"`, `"INFO"`, `"WARN"`, `"ERROR"`,
  `"FATAL"`; case-insensitive) or an integer corresponding to a log4r
  numeric threshold. Defaults to `"DEBUG"` when `level` has zero length
  (e.g. `NULL`).

## Value

`NULL`, invisibly.
