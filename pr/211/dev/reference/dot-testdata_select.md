# Choose the build whose data matches the installed packages

Lookup rule:

## Usage

``` r
.testdata_select(index, installed)
```

## Arguments

- index:

  `list` Output of
  [`.testdata_parse_index()`](https://gilead-public.github.io/gsm.core/dev/reference/dot-testdata_parse_index.md).

- installed:

  `list` Output of
  [`package_versions()`](https://gilead-public.github.io/gsm.core/dev/reference/package_versions.md)
  for `index$packages`.

## Value

`list` with `build` (one row of `index$builds`) and `match` (`"exact"`
or `"filtered"`).

## Details

1.  Exact: the installed packages' `inputs_hash` matches a build.

2.  Otherwise, filter builds package by package (in `index$packages`
    order):

    - not installed: no filter;

    - installed `RemoteSha` that appears in the index: same
      `remote_sha`;

    - otherwise (no `RemoteSha`, or an unbuilt one): same `version`, or
      if none of the remaining builds has it, `version <=` the installed
      one.

3.  Newest `built_at` among the survivors. Error if none survive.
