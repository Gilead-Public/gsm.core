# Set the logging threshold level

Controls which log messages are displayed. Messages below the threshold
are suppressed. Accepts a character log level (e.g. `"DEBUG"`, `"WARN"`)
or a log4r logger object (for backward compatibility).

## Usage

``` r
SetLogger(logger)

# S3 method for class 'character'
SetLogger(logger)

# S3 method for class 'loglevel'
SetLogger(logger)

# S3 method for class 'logger'
SetLogger(logger)

# Default S3 method
SetLogger(logger)
```

## Arguments

- logger:

  A character string (one of `"DEBUG"`, `"INFO"`, `"WARN"`, `"ERROR"`,
  `"FATAL"`) or a log4r logger object.
