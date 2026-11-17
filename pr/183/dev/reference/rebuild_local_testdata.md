# Rebuild local test data

**\[experimental\]**

## Usage

``` r
rebuild_local_testdata()
```

## Value

`character(1)` The build folder, invisibly.

## Details

When gsm packages are loaded with
[`devtools::load_all()`](https://devtools.r-lib.org/reference/load_all.html)
or installed locally (no `RemoteSha`), and no published gsm.datasim
build matches them exactly, gsm.core builds test data from them with the
function in the `gsm.testdata_builder` option: a function, or a
`"pkg::fn"` string that is resolved only when a build is needed. For
example, in `.Rprofile`:

    options(gsm.testdata_builder = "gsm.datasim::build_testdata_bundle")

The builder is called as
`builder(output_dir, overwrite = TRUE, allow_local = TRUE)` and must
write a snapshot folder (see
[`read_snapshot()`](https://gilead-public.github.io/gsm.core/dev/reference/read_snapshot.md))
to `output_dir`. Builds are kept under
`tools::R_user_dir("gsm", "cache")` and reused for the same package
versions. Because local packages have no `RemoteSha`, code changes don't
trigger a rebuild; call `rebuild_local_testdata()` after changing code.

If a published release has the same data fingerprint as a local build,
its objects are copied from the build rather than downloaded.

A tag or folder set with
[`use_testdata_tag()`](https://gilead-public.github.io/gsm.core/dev/reference/use_testdata_snapshot.md)
or
[`use_testdata_snapshot()`](https://gilead-public.github.io/gsm.core/dev/reference/use_testdata_snapshot.md)
takes priority over local builds.
