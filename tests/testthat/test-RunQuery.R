test_that("RunQuery returns correct result", {
  df <- data.frame(
    Name = c("John", "Jane", "Bob"),
    Age = c(25, 30, 35),
    Salary = c(50000, 60000, 70000)
  )

  query <- "SELECT * FROM df WHERE Age >= 30"

  expect_message(
    expect_message(
      expect_message(
        {
          result <- RunQuery(query, df)
        },
        "Creating a new temporary DuckDB connection"
      ),
      "SQL Query complete"
    ),
    "Disconnected from temporary DuckDB connection"
  )

  # Check if the result is correct
  expect_equal(nrow(result), 2)
  expect_equal(colnames(result), c("Name", "Age", "Salary"))
  expect_equal(result$Name, c("Jane", "Bob"))
  expect_equal(result$Age, c(30, 35))
  expect_equal(result$Salary, c(60000, 70000))
})

test_that("RunQuery handles empty df", {
  df <- data.frame()

  query <- "SELECT * FROM df WHERE Age >= 30"

  expect_warning(
    result <- RunQuery(query, df),
    regexp = "empty data frame"
  )

  expect_equal(nrow(result), 0)
})

test_that("RunQuery handles invalid input", {
  df <- data.frame(
    Name = c("John", "Jane", "Bob"),
    Age = c(25, 30, 35),
    Salary = c(50000, 60000, 70000)
  )

  # Define the query and mapping with invalid input types
  query <- 123

  expect_error(RunQuery(query, df))
})

test_that("RunQuery checks if strQuery contains 'FROM df'", {
  df <- data.frame(
    Name = c("John", "Jane", "Bob"),
    Age = c(25, 30, 35),
    Salary = c(50000, 60000, 70000)
  )

  query <- "SELECT * FROM mydata WHERE Age >= 30"

  expect_error(RunQuery(query, df), "strQuery must contain 'FROM df'")
})

test_that("RunQuery checks if all templated columns are found in lMapping", {
  df <- data.frame(
    Name = c("John", "Jane", "Bob"),
    Age = c(25, 30, 35),
    Salary = c(50000, 60000, 70000)
  )

  query <- "SELECT * FROM df WHERE Age >= 30"

  expect_no_error(
    suppressMessages(RunQuery(query, df))
  )
})

test_that("RunQuery applies schema appropriately (#22, #45)", {
  df <- data.frame(
    Name = c("John", "Jane", "Bob"),
    Age = c(25, 30, 35),
    Salary = c(50000, 60000, "70000"),
    Birthday = c("1990-01-01", "1987-02-02", "1985-03-03"),
    Birthtime = c("1990-01-01 06:47:00", "1987-02-02T08:15:34", "1985-03-03"),
    Tenured = c(FALSE, TRUE, TRUE)
  )
  lColumnMapping <- list(
    Name = list(
      type = "character"
    ),
    Age = list(
      type = "integer"
    ),
    Salary = list(
      type = "integer"
    ),
    Birthdate = list(
      type = "Date",
      source_col = "Birthday"
    ),
    Birthtime = list(
      type = "timestamp"
    ),
    Tenured = list(
      type = "logical"
    )
  )

  # Define the query and mapping
  query <- "SELECT Name, Age, Salary, Birthday AS Birthdate, Birthtime, Tenured FROM df WHERE Age >= 30"

  expect_no_error({
    suppressMessages({
      result <- RunQuery(
        query,
        df,
        bUseSchema = T,
        lColumnMapping = lColumnMapping
      )
    })
  })
  expect_equal(class(result$Birthtime), c("POSIXct", "POSIXt"))
  expect_equal(class(result$Birthdate), "Date")
  expect_equal(class(result$Salary), "integer")
  expect_equal(class(result$Age), "integer")
  expect_equal(class(result$Name), "character")
  expect_equal(class(result$Tenured), "logical")
})

test_that("RunQuery applies incomplete schema appropriately (#70, #71)", {
  df <- data.frame(
    Name = c("John", "Jane", "Bob"),
    Age = c(25, 30, 35),
    Salary = c(50000, 60000, "70000"),
    Birthday = c("1990-01-01", "1987-02-02", "1985-03-03")
  )
  lColumnMapping <- list(
    emaN = list(
      source = "Name"
    ),
    Age = list(
      type = "numeric"
    ),
    Salary = list(
      type = "numeric"
    )
  )

  query <- "SELECT Name as emaN FROM df WHERE Name LIKE '%o%'"

  expect_no_error({
    suppressMessages({
      result <- RunQuery(query, df, bUseSchema = T, lColumnMapping = lColumnMapping)
    })
  })
  expect_equal(class(result$emaN), class(df$Name))
})


test_that("RunQuery parses invalid date/times correctly (#44)", {
  df <- data.frame(
    Name = c("John", "Jane", "Bob"),
    Birthday = c("1990JAN01", "1987-02-30", ""),
    Birthtime = c("1990-01-32 06:47", "28FEB1987 01:45:32", ""),
    Tenured = c(FALSE, TRUE, TRUE)
  )
  lColumnMapping <- list(
    Name = list(
      type = "character"
    ),
    Birthday = list(
      type = "Date"
    ),
    Birthtime = list(
      type = "timestamp"
    )
  )

  # Define the query and mapping
  query <- "SELECT * FROM df"

  suppressWarnings(
    suppressMessages(
      result <- RunQuery(
        query,
        df,
        bUseSchema = T,
        lColumnMapping = lColumnMapping
      )
    )
  )
  expect_true(all(is.na(result$Birthday)))
  expect_true(all(is.na(result$Birthtime)))
})
