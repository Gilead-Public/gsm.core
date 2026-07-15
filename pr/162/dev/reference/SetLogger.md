# Set the logging threshold level

Controls which log messages are displayed. Messages below the threshold
are suppressed. Can accept either a character log level (e.g. "DEBUG",
"WARN") or a log4r logger object (for backward compatibility).

## Usage

``` r
SetLogger(logger)
```

## Arguments

- logger:

  A character string (one of "DEBUG", "INFO", "WARN", "ERROR", "FATAL")
  or a log4r logger object.
