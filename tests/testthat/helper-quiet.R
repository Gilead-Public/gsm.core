suppressPackageStartupMessages(suppressWarnings(library(tcltk)))

quiet_RunWorkflows <- function(...) {
  suppressWarnings(suppressMessages({
    workr::RunWorkflows(...)
  }))
}

quiet_RunWorkflow <- function(...) {
  suppressWarnings(suppressMessages({
    workr::RunWorkflow(...)
  }))
}

quiet_Analyze_NormalApprox <- function(...) {
  suppressMessages({
    Analyze_NormalApprox(...)
  })
}

quiet_Analyze_NormalApprox_PredictBounds <- function(...) {
  suppressMessages({
    Analyze_NormalApprox_PredictBounds(...)
  })
}

quiet_Analyze_Poisson_PredictBounds <- function(...) {
  suppressMessages({
    Analyze_Poisson_PredictBounds(...)
  })
}
