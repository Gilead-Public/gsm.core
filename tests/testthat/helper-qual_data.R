set.seed(123)

# ---- Source data setup -------------------------------------------------------
lSource <- gsm.core::lSource
lData <- list(
  Raw_SUBJ = lSource$Raw_SUBJ,
  Raw_AE = lSource$Raw_AE
)

# Data with missing values (15% NA's) - used in T2_2
lData_missing_values <- purrr::map(lData, function(df) {
  df %>%
    dplyr::mutate(
      dplyr::across(
        !dplyr::contains("GroupID"),
        ~ replace(., sample(dplyr::row_number(), size = .15 * dplyr::n()), NA)
      )
    )
})

# ---- Workflow path helpers (local-first, remote-optional) --------------------

# Custom metrics path - local repository only (already present in this repo)
GetYamlPathCustomMetrics <- function() {
  testthat::test_path("qual_workflows/2_metrics_custom")
}

# Expected local copies of workflows (recommended for CI stability)
GetYamlPathMetricsLocal <- function() {
  testthat::test_path("qual_workflows/2_metrics")
}

GetYamlPathMappingsLocal <- function() {
  testthat::test_path("qual_workflows/1_mappings")
}

.dir_has_yaml <- function(path) {
  isTRUE(dir.exists(path)) &&
    length(list.files(path, pattern = "\\.ya?ml$", full.names = TRUE)) > 0
}

# Try to obtain cached workflows from remote repositories.
# IMPORTANT: never hard-fail during helper sourcing; return NULL on error.
.try_get_cached_workflows <- function(...) {
  tryCatch(
    get_cached_workflows(...),
    error = function(e) {
      msg <- conditionMessage(e)
      message("NOTE: get_cached_workflows() failed; proceeding without remote workflows. Details: ", msg)
      NULL
    }
  )
}

# Resolve workflow directories:
# 1) Prefer local vendored workflows under tests/testthat/qual_workflows
# 2) Otherwise attempt to use cached/remote workflows (may be blocked in CI)
metrics_workflow_path <- NULL
mappings_workflow_path <- NULL

if (.dir_has_yaml(GetYamlPathMetricsLocal())) {
  metrics_workflow_path <- GetYamlPathMetricsLocal()
} else {
  metrics_workflow_path <- .try_get_cached_workflows(
    strPackage = "gsm.kri",
    workflow_subdir = "2_metrics",
    branch = "main",
    force_update = FALSE,
    strNames = c("kri000[12]", "cou000[12]")
  )
}

if (.dir_has_yaml(GetYamlPathMappingsLocal())) {
  mappings_workflow_path <- GetYamlPathMappingsLocal()
} else {
  mappings_workflow_path <- .try_get_cached_workflows(
    strPackage = "gsm.mapping",
    workflow_subdir = "1_mappings",
    branch = "main",
    force_update = FALSE,
    strNames = c("^AE", "^SUBJ")
  )
}

# Public helpers used by tests.
# If workflows cannot be resolved, skip tests that rely on them rather than failing.
GetYamlPathMetrics <- function() {
  if (!is.null(metrics_workflow_path)) {
    return(metrics_workflow_path)
  }
  testthat::skip("Metrics workflows unavailable (no local copy and cannot download/cache in this environment).")
}

GetYamlPathMappings <- function() {
  if (!is.null(mappings_workflow_path)) {
    return(mappings_workflow_path)
  }
  testthat::skip("Mapping workflows unavailable (no local copy and cannot download/cache in this environment).")
}

# ---- Data caching functions --------------------------------------------------

get_data_cache_dir <- function() {
  cache_dir <- file.path(tools::R_user_dir("gsm", "cache"), "processed_data")
  if (!dir.exists(cache_dir)) dir.create(cache_dir, recursive = TRUE)
  return(cache_dir)
}

get_cached_mapped_data <- function(force_refresh = FALSE) {
  cache_dir <- get_data_cache_dir()
  cache_file <- file.path(cache_dir, "mapped_data.rds")

  if (!force_refresh && file.exists(cache_file)) {
    # Check if workflows have been updated since cache was created
    workflow_dir <- GetYamlPathMappings()
    workflow_files <- list.files(workflow_dir, pattern = "\\.ya?ml$", full.names = TRUE)

    if (length(workflow_files) > 0) {
      newest_workflow <- max(file.mtime(workflow_files))
      cache_time <- file.mtime(cache_file)

      if (cache_time > newest_workflow) {
        message("Using cached mapped data.")
        return(readRDS(cache_file))
      }
    }
  }

  # Generate fresh data
  message("Updating cached mapped data...")
  mappings_wf <- workr::MakeWorkflowList(strPath = GetYamlPathMappings())

  ConsoleAppender <- log4r::console_appender(layout = gsm.core::cli_fmt)
  gsm.core::SetLogger(log4r::logger(
    threshold = "WARN",
    appenders = ConsoleAppender
  ))
  mapped_data <- workr::RunWorkflows(mappings_wf, lData)
  gsm.core::SetLogger(log4r::logger(
    "DEBUG",
    appenders = ConsoleAppender
  ))

  saveRDS(mapped_data, cache_file)
  message("Cached mapped data updated successfully.")
  return(mapped_data)
}

get_cached_mapping_output <- function(force_refresh = FALSE) {
  cache_dir <- get_data_cache_dir()
  cache_file <- file.path(cache_dir, "mapping_output.rds")

  if (!force_refresh && file.exists(cache_file)) {
    workflow_dir <- GetYamlPathMappings()
    workflow_files <- list.files(workflow_dir, pattern = "\\.ya?ml$", full.names = TRUE)

    if (length(workflow_files) > 0) {
      newest_workflow <- max(file.mtime(workflow_files))
      cache_time <- file.mtime(cache_file)

      if (cache_time > newest_workflow) {
        message("Using cached mapping output.")
        return(readRDS(cache_file))
      }
    }
  }

  # Generate fresh data
  message("Updating cached mapping output...")
  mappings_wf <- workr::MakeWorkflowList(strPath = GetYamlPathMappings())
  mapping_output <- purrr::map(mappings_wf, ~ .x$steps[[1]]$output) %>% unlist()

  saveRDS(mapping_output, cache_file)
  message("Cached mapping output updated successfully.")
  return(mapping_output)
}

# ---- Lazily-initialized globals ---------------------------------------------
# Do not hard-fail at helper source time if workflows are unavailable.
# If workflows are missing, dependent tests will be skipped via GetYamlPathMappings()/Metrics().
mapped_data <- NULL
mapping_output <- NULL
mappings_wf <- NULL

if (!is.null(mappings_workflow_path)) {
  delayedAssign("mapped_data", get_cached_mapped_data())
  delayedAssign("mapping_output", get_cached_mapping_output())
  delayedAssign("mappings_wf", workr::MakeWorkflowList(strPath = GetYamlPathMappings()))
}

# ---- Robust workflow runner that handles errors gracefully -------------------

robust_runworkflow <- function(
  lWorkflow,
  lData,
  steps = seq(lWorkflow$steps),
  bReturnResult = TRUE,
  bKeepInputData = TRUE
) {
  uid <- paste0(lWorkflow$meta$Type, "_", lWorkflow$meta$ID)
  lWorkflow$lData <- lData

  if ("spec" %in% names(lWorkflow)) {
    CheckSpec(lData, lWorkflow$spec)
  } else {
    lWorkflow$spec <- NULL
  }

  if (length(steps) > 1) {
    lWorkflow$steps <- lWorkflow$steps[steps]
  } else if (length(steps) == 1) {
    lWorkflow$steps <- list(lWorkflow$steps[[steps]])
  }

  # Run each step with error handling
  for (step in lWorkflow$steps) {
    result0 <- purrr::safely(
      ~ workr::RunStep(
        lStep = step,
        lData = lWorkflow$lData,
        lMeta = lWorkflow$meta
      )
    )()

    if (names(result0[!purrr::map_vec(result0, is.null)]) == "error") {
      cli::cli_alert_danger(paste0(
        "Error:`", result0$error$message, "`: error message stored as result"
      ))
      result1 <- result0$error$message
    } else {
      result1 <- result0$result
    }

    lWorkflow$lData[[step$output]] <- result1
    lWorkflow$lResult <- result1
  }

  if (!bKeepInputData) {
    outputs <- lWorkflow$steps %>% purrr::map_chr(~ .x$output)
    lWorkflow$lData <- lWorkflow$lData[outputs]
  }

  if (bReturnResult) {
    return(lWorkflow$lData)
  } else {
    return(lWorkflow)
  }
}

# ---- Get relevant data for a workflow ---------------------------------------
# Wrapper for robust_runworkflow
get_data <- function(lWorkflow, data) {
  if ("spec" %in% names(lWorkflow)) lWorkflow <- list(lWorkflow)

  maps_needed_index <- purrr::map(lWorkflow, ~ names(.x$spec)) %>%
    unlist() %>%
    unique()

  # If mapping_output isn't available, skip gracefully.
  if (is.null(mapping_output)) {
    testthat::skip("Mapping output unavailable because mapping workflows could not be resolved.")
  }

  maps_needed <- names(mapping_output[which(
    mapping_output %in% maps_needed_index
  )])

  # This code temporarily deals with column mismatches in gsm.core vs
  # gsm.mapping and should be removed when all packages are released.
  suppressWarnings({
    mapped_needed_data <- workr::RunWorkflows(mappings_wf[maps_needed], data)
  })
  return(mapped_needed_data)
}
