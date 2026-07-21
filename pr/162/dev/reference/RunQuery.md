# Run a SQL query on a data frame or DuckDB table

**\[deprecated\]**

`RunQuery()` has moved to
[`workr::RunQuery()`](https://gilead-biostats.github.io/workr/reference/RunQuery.html).
This wrapper remains for backward compatibility in `{gsm.core}`.

## Usage

``` r
RunQuery(strQuery, df, bUseSchema = FALSE, lColumnMapping = NULL)
```

## Arguments

- strQuery:

  `character` SQL query to run, containing placeholders `"FROM df"`.

- df:

  `data.frame` or `tbl_dbi` A data frame or DuckDB lazy table to use in
  the SQL query.

- bUseSchema:

  `boolean` should we use a schema to enforce data types. Defaults to
  `FALSE`.

- lColumnMapping:

  `list` a namesd list of column specifications for a single data.frame.
  Required if `bUseSchema` is `TRUE`.

## Value

`data.frame` containing the results of the SQL query.

## Examples

``` r
df <- data.frame(
  Name = c("John", "Jane", "Bob"),
  Age = c(25, 30, 35),
  Salary = c(50000, 60000, 70000)
)
query <- "SELECT * FROM df WHERE AGE > 30"

result <- workr::RunQuery(query, df)
#> [INFO] Creating a new temporary DuckDB connection.
#> duckdb is keeping downloaded extensions in a temporary directory:
#> ℹ /tmp/RtmpKZj3K7/duckdb/extensions
#> This is removed when the R session ends, so extensions are re-downloaded each session.
#> ℹ To keep them, point `options(duckdb.extension_directory =)` or the `DUCKDB_EXTENSION_DIRECTORY` environment variable at a permanent path.
#> [INFO] SQL Query complete: 1 rows returned.
#> [INFO] Disconnected from temporary DuckDB connection.
```
