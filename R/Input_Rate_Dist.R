#' Input_Rate_Dist
#'
#' @description
#' `r lifecycle::badge("experimental")`
#'
#' Calculate group-level category distributions (breakdowns) of a metric's
#' numerator and/or denominator.
#'
#' @details
#' This function takes the same inputs as [Input_Rate()] plus the names of one
#' or more category columns in `dfNumerator` and/or `dfDenominator`. For each
#' group and category it counts the numerator (or denominator) records that
#' fall in that category. The `Total` of each breakdown is the group's
#' numerator (or denominator) as calculated by [Input_Rate()], so the
#' breakdowns reconcile with the metric by construction.
#'
#' @section Data Specification:
#' `dfSubjects`, `dfNumerator` and `dfDenominator` must meet the requirements
#' of [Input_Rate()]. In addition, every column named in `strNumeratorCatCols`
#' must exist in `dfNumerator`, and every column named in
#' `strDenominatorCatCols` must exist in `dfDenominator`.
#'
#' Category values are counted as follows:
#' - Each category row is assigned to its subject's group via `dfSubjects`.
#'   Rows for subjects that are not in `dfSubjects`, or whose group is missing,
#'   are dropped, exactly as in [Input_Rate()].
#' - When `strCatDelim` is supplied, multi-value cells (e.g. `"EXCL07|INCL06"`)
#'   are split on the delimiter and trimmed. A record then counts once in each
#'   of its categories; repeated values within one cell count once. For these
#'   variables, the category counts can add up to more than `Total`.
#'   `strCatDelim` applies to every category column.
#' - Missing and blank values are reported as the category `"Not recorded"`.
#' - Every group receives a row for every category observed anywhere in the
#'   data for that source and variable. Categories that a group does not have
#'   are reported with `Count = 0` and `Participants = 0`.
#' - `Count` uses the same method as the corresponding [Input_Rate()] side:
#'   with `"Count"` it is the number of records in the category; with `"Sum"`
#'   it is the sum of `strNumeratorCol` / `strDenominatorCol` in the category.
#'   `Participants` is the number of distinct subjects in the category.
#'
#' @inheritParams Input_Rate
#' @param strNumeratorCatCols `character` Column name(s) in `dfNumerator` to
#'   break the numerator down by. Default: `NULL` (no numerator breakdowns).
#' @param strDenominatorCatCols `character` Column name(s) in `dfDenominator`
#'   to break the denominator down by. Default: `NULL` (no denominator
#'   breakdowns).
#' @param strCatDelim `character` Delimiter used to split multi-value category
#'   cells. Default: `NULL` (no splitting).
#'
#' @return `data.frame` with one row per group, source, variable and category,
#'   and the following specification:
#'
#' | Column Name  | Description                                                     | Type      |
#' |--------------|-----------------------------------------------------------------|-----------|
#' | GroupID      | The group ID                                                    | Character |
#' | GroupLevel   | The group type                                                  | Character |
#' | Source       | `"Numerator"` or `"Denominator"`                                | Character |
#' | Variable     | The category column name                                        | Character |
#' | Category     | The category value; `"Not recorded"` when missing or blank      | Character |
#' | Count        | Records (or summed values) in the category                      | Numeric   |
#' | Participants | Distinct subjects in the category                               | Integer   |
#' | Total        | The group's numerator or denominator from [Input_Rate()]        | Numeric   |
#' | Percent      | `Count / Total`; `NA` when `Total` is 0                         | Numeric   |
#'
#' When no category columns are supplied, a zero-row data frame with these
#' columns is returned.
#'
#' @examplesIf testdata_is_available("lSource")
#' # Break down AEs by seriousness and participants by IP non-starter status,
#' # per site
#' dfDist <- Input_Rate_Dist(
#'   dfSubjects = gsm.core::lSource$Raw_SUBJ,
#'   dfNumerator = gsm.core::lSource$Raw_AE,
#'   dfDenominator = gsm.core::lSource$Raw_SUBJ,
#'   strSubjectCol = "subjid",
#'   strGroupCol = "invid",
#'   strGroupLevel = "Site",
#'   strNumeratorMethod = "Count",
#'   strDenominatorMethod = "Count",
#'   strNumeratorCatCols = "aeser",
#'   strDenominatorCatCols = "drv_ip_nonstarter_status"
#' )
#'
#' @export
#' @keywords internal

Input_Rate_Dist <- function(
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
) {
  strNumeratorMethod <- match.arg(strNumeratorMethod)
  strDenominatorMethod <- match.arg(strDenominatorMethod)

  check_cat_cols(strNumeratorCatCols, dfNumerator, "strNumeratorCatCols", "dfNumerator")
  check_cat_cols(strDenominatorCatCols, dfDenominator, "strDenominatorCatCols", "dfDenominator")
  stop_if(
    cnd = !is.null(strCatDelim) &&
      (!is.character(strCatDelim) || length(strCatDelim) != 1 || is.na(strCatDelim) || strCatDelim == ""),
    message = "`strCatDelim` must be NULL or a single non-empty character string"
  )

  dfInput <- Input_Rate(
    dfSubjects = dfSubjects,
    dfNumerator = dfNumerator,
    dfDenominator = dfDenominator,
    strGroupCol = strGroupCol,
    strGroupLevel = strGroupLevel,
    strSubjectCol = strSubjectCol,
    strNumeratorMethod = strNumeratorMethod,
    strDenominatorMethod = strDenominatorMethod,
    strNumeratorCol = strNumeratorCol,
    strDenominatorCol = strDenominatorCol
  )

  dfGroups <- dfInput %>%
    group_by(.data$GroupID, .data$GroupLevel) %>%
    summarise(
      Numerator = sum(.data$Numerator),
      Denominator = sum(.data$Denominator),
      .groups = "drop"
    )

  dfSubjectGroups <- dfInput %>%
    select("SubjectID", "GroupID")

  lSides <- list(
    list(
      source = "Numerator", df = dfNumerator, catCols = strNumeratorCatCols,
      method = strNumeratorMethod, valueCol = strNumeratorCol
    ),
    list(
      source = "Denominator", df = dfDenominator, catCols = strDenominatorCatCols,
      method = strDenominatorMethod, valueCol = strDenominatorCol
    )
  )

  lDist <- purrr::map(lSides, function(side) {
    purrr::map(side$catCols, function(strCatCol) {
      dist_one_variable(
        df = side$df,
        strCatCol = strCatCol,
        strSource = side$source,
        strSubjectCol = strSubjectCol,
        strMethod = side$method,
        strValueCol = side$valueCol,
        strCatDelim = strCatDelim,
        dfGroups = dfGroups,
        dfSubjectGroups = dfSubjectGroups
      )
    })
  }) %>%
    purrr::list_flatten()

  dfTemplate <- tibble(
    GroupID = dfGroups$GroupID[0],
    GroupLevel = character(),
    Source = character(),
    Variable = character(),
    Category = character(),
    Count = numeric(),
    Participants = integer(),
    Total = numeric(),
    Percent = numeric()
  )

  dfDist <- bind_rows(dfTemplate, lDist)

  return(dfDist)
}

check_cat_cols <- function(strCatCols, df, strArg, strDf) {
  if (is.null(strCatCols)) {
    return(invisible(NULL))
  }

  stop_if(
    cnd = !is.character(strCatCols) || anyNA(strCatCols) || any(strCatCols == ""),
    message = glue::glue("`{strArg}` must be NULL or a character vector of column names")
  )

  missingCols <- setdiff(strCatCols, colnames(df))
  stop_if(
    cnd = length(missingCols) > 0,
    message = glue::glue(
      "`{strArg}` column(s) not found in `{strDf}`: {paste(missingCols, collapse = ', ')}"
    )
  )

  invisible(NULL)
}

split_categories <- function(vCategory, strCatDelim = NULL) {
  vCategory <- as.character(vCategory)
  lTokens <- if (is.null(strCatDelim)) {
    as.list(vCategory)
  } else {
    strsplit(vCategory, strCatDelim, fixed = TRUE)
  }

  purrr::map(lTokens, function(tokens) {
    tokens <- trimws(tokens)
    tokens <- unique(tokens[!is.na(tokens) & tokens != ""])
    if (length(tokens) == 0) "Not recorded" else tokens
  })
}

dist_one_variable <- function(
  df,
  strCatCol,
  strSource,
  strSubjectCol,
  strMethod,
  strValueCol,
  strCatDelim,
  dfGroups,
  dfSubjectGroups
) {
  vWeight <- if (strMethod == "Count") {
    rep(1, nrow(df))
  } else {
    dplyr::coalesce(as.numeric(df[[strValueCol]]), 0)
  }

  lTokens <- split_categories(df[[strCatCol]], strCatDelim)
  vIndex <- rep(seq_along(lTokens), lengths(lTokens))

  dfLong <- tibble(
    SubjectID = df[[strSubjectCol]][vIndex],
    Weight = vWeight[vIndex],
    Category = unlist(lTokens, use.names = FALSE) %||% character()
  ) %>%
    inner_join(dfSubjectGroups, by = "SubjectID")

  vCategories <- sort(unique(dfLong$Category))
  vCategories <- c(setdiff(vCategories, "Not recorded"), intersect("Not recorded", vCategories))

  dfCounts <- dfLong %>%
    group_by(.data$GroupID, .data$Category) %>%
    summarise(
      Count = sum(.data$Weight),
      Participants = n_distinct(.data$SubjectID),
      .groups = "drop"
    )

  dfGroups %>%
    transmute(
      .data$GroupID,
      .data$GroupLevel,
      Total = .data[[strSource]]
    ) %>%
    tidyr::expand_grid(Category = vCategories) %>%
    left_join(dfCounts, by = c("GroupID", "Category")) %>%
    transmute(
      .data$GroupID,
      .data$GroupLevel,
      Source = strSource,
      Variable = strCatCol,
      .data$Category,
      Count = dplyr::coalesce(.data$Count, 0),
      Participants = dplyr::coalesce(.data$Participants, 0L),
      .data$Total,
      Percent = dplyr::if_else(.data$Total == 0, NA_real_, .data$Count / .data$Total)
    )
}
