# Input_Rate_Dist

**\[experimental\]**

Calculate group-level category distributions (breakdowns) of a metric's
numerator and/or denominator.

## Usage

``` r
Input_Rate_Dist(
  dfSubjects,
  dfNumerator,
  dfDenominator,
  strGroupCol = "GroupID",
  strGroupLevel = NULL,
  strSubjectCol = "SubjectID",
  strNumeratorMethod = c("Count", "Sum"),
  strDenominatorMethod = c("Count", "Sum"),
  strNumeratorCol = NULL,
  strDenominatorCol = NULL,
  strNumeratorCatCols = NULL,
  strDenominatorCatCols = NULL,
  strCatDelim = NULL
)
```

## Arguments

- dfSubjects:

  `data.frame` with columns for SubjectID and any other relevant subject
  information

- dfNumerator:

  `data.frame` with a column for SubjectID and `strNumeratorCol` if
  `strNumeratorMethod` is "Sum"

- dfDenominator:

  `data.frame` with a column for SubjectID and `strDenominatorCol` if
  `strDenominatorMethod` is "Sum"

- strGroupCol:

  `character` Column name in `dfSubjects` to use for grouping. Default:
  "GroupID"

- strGroupLevel:

  `character` value for the group level. Default: NULL which is parsed
  to `strGroupCol`

- strSubjectCol:

  `character` Column name in `dfSubjects` to use for subject ID.
  Default: "SubjectID"

- strNumeratorMethod:

  `character` Method to calculate numerator. Default: "Count"

- strDenominatorMethod:

  `character` Method to calculate denominator. Default: "Count"

- strNumeratorCol:

  `character` Column name in `dfNumerator` to use for numerator
  calculation. Default: NULL

- strDenominatorCol:

  `character` Column name in `dfDenominator` to use for denominator
  calculation. Default: NULL

- strNumeratorCatCols:

  `character` Column name(s) in `dfNumerator` to break the numerator
  down by. Default: `NULL` (no numerator breakdowns).

- strDenominatorCatCols:

  `character` Column name(s) in `dfDenominator` to break the denominator
  down by. Default: `NULL` (no denominator breakdowns).

- strCatDelim:

  `character` Delimiter used to split multi-value category cells.
  Default: `NULL` (no splitting).

## Value

`data.frame` with one row per group, source, variable and category, and
the following specification:

|  |  |  |
|----|----|----|
| Column Name | Description | Type |
| GroupID | The group ID | Character |
| GroupLevel | The group type | Character |
| Source | `"Numerator"` or `"Denominator"` | Character |
| Variable | The category column name | Character |
| Category | The category value; `"Not recorded"` when missing or blank | Character |
| Count | Records (or summed values) in the category | Numeric |
| Participants | Distinct subjects in the category | Integer |
| Total | The group's numerator or denominator from [`Input_Rate()`](https://gilead-public.github.io/gsm.core/dev/reference/Input_Rate.md) | Numeric |
| Percent | `Count / Total`; `NA` when `Total` is 0 | Numeric |

When no category columns are supplied, a zero-row data frame with these
columns is returned.

## Details

This function takes the same inputs as
[`Input_Rate()`](https://gilead-public.github.io/gsm.core/dev/reference/Input_Rate.md)
plus the names of one or more category columns in `dfNumerator` and/or
`dfDenominator`. For each group and category it counts the numerator (or
denominator) records that fall in that category. The `Total` of each
breakdown is the group's numerator (or denominator) as calculated by
[`Input_Rate()`](https://gilead-public.github.io/gsm.core/dev/reference/Input_Rate.md),
so the breakdowns reconcile with the metric by construction.

## Data Specification

`dfSubjects`, `dfNumerator` and `dfDenominator` must meet the
requirements of
[`Input_Rate()`](https://gilead-public.github.io/gsm.core/dev/reference/Input_Rate.md).
In addition, every column named in `strNumeratorCatCols` must exist in
`dfNumerator`, and every column named in `strDenominatorCatCols` must
exist in `dfDenominator`.

Category values are counted as follows:

- Each category row is assigned to its subject's group via `dfSubjects`.
  Rows for subjects that are not in `dfSubjects`, or whose group is
  missing, are dropped, exactly as in
  [`Input_Rate()`](https://gilead-public.github.io/gsm.core/dev/reference/Input_Rate.md).

- When `strCatDelim` is supplied, multi-value cells (e.g.
  `"EXCL07|INCL06"`) are split on the delimiter and trimmed. A record
  then counts once in each of its categories; repeated values within one
  cell count once. For these variables, the category counts can add up
  to more than `Total`. `strCatDelim` applies to every category column.

- Missing and blank values are reported as the category
  `"Not recorded"`.

- Every group receives a row for every category observed anywhere in the
  data for that source and variable. Categories that a group does not
  have are reported with `Count = 0` and `Participants = 0`.

- `Count` uses the same method as the corresponding
  [`Input_Rate()`](https://gilead-public.github.io/gsm.core/dev/reference/Input_Rate.md)
  side: with `"Count"` it is the number of records in the category; with
  `"Sum"` it is the sum of `strNumeratorCol` / `strDenominatorCol` in
  the category. `Participants` is the number of distinct subjects in the
  category.

## Examples

``` r
# Break down AEs by seriousness and participants by IP non-starter status,
# per site
dfDist <- Input_Rate_Dist(
  dfSubjects = gsm.core::lSource$Raw_SUBJ,
  dfNumerator = gsm.core::lSource$Raw_AE,
  dfDenominator = gsm.core::lSource$Raw_SUBJ,
  strSubjectCol = "subjid",
  strGroupCol = "invid",
  strGroupLevel = "Site",
  strNumeratorMethod = "Count",
  strDenominatorMethod = "Count",
  strNumeratorCatCols = "aeser",
  strDenominatorCatCols = "drv_ip_nonstarter_status"
)
```
