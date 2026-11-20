# Set the active log appender

Sets the function used to emit log messages. The appender must accept
`level`, `message`, and `cli_detail` arguments (see
[`cli_fmt()`](https://gilead-public.github.io/gsm.core/dev/reference/cli_fmt.md)).

## Usage

``` r
SetLogAppender(appender = cli_fmt)
```

## Arguments

- appender:

  A function to use as the log appender. Defaults to
  [cli_fmt](https://gilead-public.github.io/gsm.core/dev/reference/cli_fmt.md).

## Value

`NULL`, invisibly.
