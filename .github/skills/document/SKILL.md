---
name: document
description: Document package functions. Use when asked to document functions.
---

# Document functions

*All* functions should be documented in {roxygen2} `#'` style, including internal/unexported functions.

- Run `devtools::document()` after changing any roxygen2 docs.
- Use sentence case for all headings

## Lifecycle badges

Exported functions include a lifecycle badge at the top of their `@description`:

```r
#' @description
#' `r lifecycle::badge("stable")`
#'
#' One-sentence description.
```

New functions start with `"experimental"`, changing to `"stable"` when finalized.

## Shared parameters

**Parameters used in more than one function go in `R/aaa-shared.R`** under `@name shared-params`; functions inherit them with `@inheritParams shared-params`. The file alphabetizes parameters, uses `@keywords internal`, and ends with `NULL`.

## Parameter documentation

```r
#' @param paramName (`TYPE`) One sentence description. Can include [cross_references()].
#'   Additional details on continuation lines if needed.
```

For `TYPE`, use: `character`, `length-1 character`, `length-1 logical`, `data.frame`, `list`, `Date`, `length-1 integer`, `environment`.

## Parameter naming conventions

**Hungarian-style prefixes** indicate parameter type:
- `b*` - Logical (boolean): `bUselData`
- `d*` - Date: `dSnapshotDate`, `dPrevSnapshotDate`
- `df*` - Data frame: `dfResults`, `dfMetrics`, `dfBounds`
- `dttm*` - Datetime/POSIXct: `dttmTimestamp`
- `env*` - Environment: `envCall`
- `fct*` - Factor: `fctDisposition`
- `int*` - Integer: `intPageMax`, `intLineStart`
- `l*` - List: `lAnalysis`, `lWorkflows`, `lMetric`
- `obj*` - Any object: `objShape`
- `str*` - String or character vector: `strName`, `strStudyID`, `strMetrics`, `strIDColumns`
- `v*` - Numeric vector: `vThreshold`

## Return value documentation

Use `@returns` (not `@return`):

```r
#' @returns A data frame.

#' @returns A `data.frame` with columns:
#'   - `GroupID`: Group identifier.
#'   - `MetricID`: Metric identifier.
#'   - `SnapshotDate`: Date of the snapshot.

#' @returns The input `dfResults`, invisibly.

#' @returns `NULL` (invisibly).
```

## Cross-references

Use square brackets for function cross-references:
- External packages: `[tibble::tibble()]`, `[glue::glue()]`
- Internal functions: `[MakeBounds()]`, `[BindResults()]`

## Examples sections

```r
#' @examplesIf interactive()    # use for interactive/network-dependent functions
#'   MakeBounds(
#'     dfResults = reportingResults,
#'     dfMetrics = reportingMetrics
#'   )

#' @examples                    # use for self-contained examples
#' library(gsm.core)
#' MakeBounds(
#'   dfResults = reportingResults,
#'   dfMetrics = reportingMetrics
#' )
```

`@examplesIf interactive()` skips examples during `R CMD check`.

## Grouping related documentation

Use `@rdname` to group related functions (especially S3 methods) under one help page:

```r
#' Printing gsm.reporting objects
#' @name printing
NULL

#' @rdname printing
#' @export
print.gsm_Object <- function(x, ...) { ... }

#' @rdname printing
#' @export
format.gsm_Object <- function(...) { ... }
```

## S3 method exports

For S3 methods of functions from other packages:
```r
#' @exportS3Method dplyr::filter
filter.gsm_Results <- function(.data, ...) { ... }
```

## Internal functions

```r
#' Title in sentence case
#'
#' @inheritParams shared-params
#' @returns Use the rules as described above.
#' @keywords internal
```

No `@description`, no blank `#'` lines between sections, no `@examples`/`@examplesIf`.
