# Which installed packages are newer than recorded versions?

Which installed packages are newer than recorded versions?

## Usage

``` r
.fresh_packages_newer(installed, recorded)
```

## Arguments

- installed:

  `list` Output of
  [`package_versions()`](https://gilead-public.github.io/gsm.core/dev/reference/package_versions.md).

- recorded:

  `list` The same shape, e.g. from a snapshot. `remote_sha` may be
  absent.

## Value

`character` Names of packages with a higher version, or the same version
but a different `remote_sha`. Packages that aren't installed or recorded
are ignored.
