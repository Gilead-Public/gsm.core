# Extracted from test-RunStep.R:42

# test -------------------------------------------------------------------------
lStep <- list(name = "dummy_function", params = list(x = "lMeta", y = "lData"))
lData <- list(data1 = 100)
lMeta <- list(meta1 = 200)
expect_message(
    expect_message(
      expect_message(
        expect_message(
          expect_message(
            expect_message(
              {
                result <- workr::RunStep(lStep, lData, lMeta)
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
