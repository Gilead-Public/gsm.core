test_that("gsm.core::RunStep forwards to workr with a deprecation warning", {
  lStep <- list(name = "dummy_function", params = list(x = "lMeta", y = "lData"))
  lData <- list(data1 = 100)
  lMeta <- list(meta1 = 200)

  expected <- suppressMessages(workr::RunStep(lStep, lData, lMeta))

  expect_warning(
    result <- suppressMessages(gsm.core::RunStep(lStep, lData, lMeta)),
    "deprecated"
  )
  expect_equal(result, expected)
})

test_that("Handles lMeta and lData parameters correctly", {
  lStep <- list(name = "dummy_function", params = list(x = "lMeta", y = "lData"))
  lData <- list(data1 = 100)
  lMeta <- list(meta1 = 200)

  msgs <- capture_messages({
    result <- workr::RunStep(lStep, lData, lMeta)
  })
  # Assert each expected message individually rather than relying on regex
  # alternation (which would pass on any single match).
  expect_match(msgs, "Evaluating 2 parameter", all = FALSE)
  expect_match(msgs, "x = lMeta", all = FALSE)
  expect_match(msgs, "y = lData", all = FALSE)
  expect_match(msgs, "Calling", all = FALSE)

  expect_equal(result$x, lMeta)
  expect_equal(result$y, lData)
})

test_that("Handles parameters referencing elements within lMeta and lData", {
  lStep <- list(name = "dummy_function", params = list(x = "meta1", y = "data1"))
  lData <- list(data1 = 100)
  lMeta <- list(meta1 = 200)

  suppressMessages({
    result <- workr::RunStep(lStep, lData, lMeta)
  })
  expect_equal(result$x, 200)
  expect_equal(result$y, 100)
})

test_that("Passes direct value parameters correctly", {
  lStep <- list(name = "dummy_function", params = list(x = "meta1", y = "100"))
  lData <- list(data1 = 100)
  lMeta <- list(meta1 = 200)

  suppressMessages({
    result <- workr::RunStep(lStep, lData, lMeta)
  })
  expect_equal(result$x, 200)
  expect_equal(result$y, "100")
})

test_that("Passes direct value vector parameters correctly (#23)", {
  lStep <- list(
    name = "dummy_function",
    params = list(x = "meta1", y = c(1, 2, 3))
  )
  lMeta <- list(meta1 = 200)

  suppressMessages(expect_message(
    {
      result <- workr::RunStep(lStep, lData, lMeta)
    },
    "y is of length 3"
  ))
  expect_equal(result$x, 200)
  expect_equal(result$y, c(1, 2, 3))
})

test_that("Handles multiple parameters and function invocation correctly", {
  lStep <- list(name = "another_dummy_function", params = list(a = "meta1", b = "data1", c = "some_value"))
  lData <- list(data1 = 300)
  lMeta <- list(meta1 = 400)

  suppressMessages({
    result <- workr::RunStep(lStep, lData, lMeta)
  })
  expect_equal(result$a, 400)
  expect_equal(result$b, 300)
  expect_equal(result$c, "some_value")
})

test_that("RunStep will run a function from a namespace", {
  lStep <- list(name = "dplyr::glimpse", params = list(head(Theoph)))
  lData <- list(data1 = 300)
  lMeta <- list(meta1 = 400)

  expect_output({
    suppressMessages({
      result <- workr::RunStep(lStep, lData, lMeta)
    })
  })
  expect_equal(result, head(Theoph))
})

test_that("RunStep will run a function without a namespace", {
  lStep <- list(name = "glimpse", params = list(head(Theoph)))
  lData <- list(data1 = 300)
  lMeta <- list(meta1 = 400)

  expect_output({
    suppressMessages({
      result <- workr::RunStep(lStep, lData, lMeta)
    })
  })
  expect_equal(result, head(Theoph))
})

test_that("RunStep will run a function with no parameters (#31)", {
  wd_path <- getwd()

  lStep <- list(name = "getwd")
  suppressMessages({
    result <- workr::RunStep(lStep, list(), list())
  })
  expect_equal(result, wd_path)
})
