#' Run a SQL query on a data frame or DuckDB table
#'
#' @description
#' `r lifecycle::badge("deprecated")`
#'
#' `RunQuery()` has moved to `workr::RunQuery()`. This wrapper remains for
#' backward compatibility in `{gsm.core}`.
#'
#' @param strQuery `character` SQL query to run, containing placeholders `"FROM df"`.
#' @param df `data.frame` or `tbl_dbi` A data frame or DuckDB lazy table to use in the SQL query.
#' @param bUseSchema `boolean` should we use a schema to enforce data types. Defaults to `FALSE`.
#' @param lColumnMapping `list` a namesd list of column specifications for a single data.frame.
#' Required if `bUseSchema` is `TRUE`.
#'
#' @return `data.frame` containing the results of the SQL query.
#'
#' @examplesIf rlang::is_installed(c("DBI", "dbplyr", "duckdb"))
#' df <- data.frame(
#'   Name = c("John", "Jane", "Bob"),
#'   Age = c(25, 30, 35),
#'   Salary = c(50000, 60000, 70000)
#' )
#' query <- "SELECT * FROM df WHERE AGE > 30"
#'
#' result <- workr::RunQuery(query, df)
#'
#' @export
RunQuery <- function(strQuery, df, bUseSchema = FALSE, lColumnMapping = NULL) {
  lifecycle::deprecate_warn(
    when = "1.3.0",
    what = "gsm.core::RunQuery()",
    with = "workr::RunQuery()"
  )

  workr::RunQuery(
    strQuery = strQuery,
    df = df,
    bUseSchema = bUseSchema,
    lColumnMapping = lColumnMapping
  )
}
