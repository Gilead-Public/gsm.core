# Stop execution if a condition is true

A thin wrapper around
[`LogMessage()`](https://gilead-public.github.io/gsm.core/dev/reference/LogMessage.md)
that emits an `"ERROR"`-level message (triggering
[`cli::cli_abort()`](https://cli.r-lib.org/reference/cli_abort.html))
when `cnd` is `TRUE`.

## Usage

``` r
stop_if(cnd, message)
```

## Arguments

- cnd:

  Logical scalar. When `TRUE`, an error is raised.

- message:

  Character string to display; may contain glue-style placeholders.

## Value

`NULL`, invisibly, if `cnd` is `FALSE`. Does not return if `cnd` is
`TRUE`.
