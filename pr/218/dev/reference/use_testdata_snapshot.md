# Choose which test data gsm.core uses

**\[experimental\]**

## Usage

``` r
use_testdata_snapshot(dir = Sys.getenv("GSM_TESTDATA_SNAPSHOT"))

use_testdata_tag(tag = Sys.getenv("GSM_TESTDATA_TAG"))
```

## Arguments

- dir:

  `character(1)` Path to a local snapshot folder. `NULL` or `""` stops
  using one.

- tag:

  `character(1)` A release tag. `NULL` or `""` stops pinning one.

## Value

`character(1)` The previous value (or `NULL`), invisibly, so it can be
restored later.

## Details

By default, gsm.core uses the gsm.datasim test data release built with
the gsm packages you have installed (see the "Release selection" section
of
[lSource](https://gilead-public.github.io/gsm.core/dev/reference/lSource.md)).
These functions override that choice:

- `use_testdata_snapshot()`: read from a local snapshot folder
  containing `snapshot.json` and the files it lists, e.g. an unzipped
  `data-<id>.zip` release asset, for offline work or to test an
  unpublished bundle. Nothing is downloaded or cached. The folder is
  used even if installed packages are newer than the snapshot (with a
  message). Takes priority over `use_testdata_tag()`.

- `use_testdata_tag()`: use one exact gsm.datasim release, e.g.
  `"data-8cde53949d4d"`.

Each function's default reads an environment variable
(`GSM_TESTDATA_SNAPSHOT`, `GSM_TESTDATA_TAG`). gsm.core calls both with
their defaults when it loads, so setting the variables (e.g. in
`.Renviron` or CI) applies them every session. Calling a function
changes the setting for the current session only.

A folder is checked as soon as it's set (or, for
`GSM_TESTDATA_SNAPSHOT`, when gsm.core loads, with a warning instead of
an error). A tag is checked when the test data is next accessed.

## Examples

``` r
old <- use_testdata_tag("data-8cde53949d4d")
use_testdata_tag(old)

# Re-read the environment variable:
use_testdata_tag()

# Temporarily, e.g. in a test:
# withr::defer(use_testdata_tag(use_testdata_tag("data-...")))
```
