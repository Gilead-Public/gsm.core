# Installed versions of the indexed packages

A wrapper around
[`package_versions()`](https://gilead-public.github.io/gsm.core/dev/reference/package_versions.md)
that tests can mock.

## Usage

``` r
.testdata_installed(packages)
```

## Arguments

- packages:

  `character` Package names.

## Value

`list` Output of
[`package_versions()`](https://gilead-public.github.io/gsm.core/dev/reference/package_versions.md).
