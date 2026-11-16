# NAMESPACE directives for fresh bindings

Bindings created by
[`keep_fresh()`](https://gilead-public.github.io/gsm.core/dev/reference/keep_fresh.md)
in `.onLoad` don't exist when roxygen2 scans the package, so `@export`
can't see them. Use this with `@evalNamespace` to export them from the
same table that creates them:

## Usage

``` r
fresh_exports(names)
```

## Arguments

- names:

  `character` Binding names.

## Value

`character` `export()` directives.

## Details

    #' @evalNamespace fresh_exports(names(my_setters))
    NULL

Document each binding as a dataset with `@name`, `@docType data`, and an
explicit `@format`/`@usage`. Don't compute `@format` from the object
(e.g. `dim(x)`): that would trigger the setter during `document()`.
