test_that("Handles lMeta and lData parameters correctly", {
  lStep <- list(name = "dummy_function", params = list(x = "lMeta", y = "lData"))
  lData <- list(data1 = 100)
  lMeta <- list(meta1 = 200)

  # Exhaustively capture all the message lines here so we can be confident and
  # skip this in the rest of these.
  expect_message(
    expect_message(
      expect_message(
        expect_message(
          expect_message(
            expect_message(
              {
                result <- RunStep(lStep, lData, lMeta)
              },
              "Evaluating 2 parameter"
            ),
            "x = lMeta"
          ),
          "y = lData"
        ),
        "\\s"
      ),
      "\\s"
    ),
    "Calling"
  )
  expect_equal(result$x, lMeta)
  expect_equal(result$y, lData)
})

test_that("Handles parameters referencing elements within lMeta and lData", {
  lStep <- list(name = "dummy_function", params = list(x = "meta1", y = "data1"))
  lData <- list(data1 = 100)
  lMeta <- list(meta1 = 200)

  suppressMessages({
    result <- RunStep(lStep, lData, lMeta)
  })
  expect_equal(result$x, 200)
  expect_equal(result$y, 100)
})

test_that("Passes direct value parameters correctly", {
  lStep <- list(name = "dummy_function", params = list(x = "meta1", y = "100"))
  lData <- list(data1 = 100)
  lMeta <- list(meta1 = 200)

  suppressMessages({
    result <- RunStep(lStep, lData, lMeta)
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
      result <- RunStep(lStep, lData, lMeta)
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
    result <- RunStep(lStep, lData, lMeta)
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
      result <- RunStep(lStep, lData, lMeta)
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
      result <- RunStep(lStep, lData, lMeta)
    })
  })
  expect_equal(result, head(Theoph))
})

test_that("RunStep will run a function with no parameters (#31)", {
  wd_path <- getwd()

  lStep <- list(name = "getwd")
  suppressMessages({
    result <- RunStep(lStep, list(), list())
  })
  expect_equal(result, wd_path)
})
