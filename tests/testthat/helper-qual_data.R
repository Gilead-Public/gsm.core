set.seed(123)

# Source data setup
lSource <- gsm.core::lSource
lData <- list(
  Raw_SUBJ = lSource$Raw_SUBJ,
  Raw_AE = lSource$Raw_AE
)

# Data with missing values (15% NA's) - used in T2_2
lData_missing_values <- map(lData, function(df) {
  df %>%
    mutate(
      across(
        !contains("GroupID"),
        ~ replace(., sample(row_number(), size = .15 * n()), NA)
      )
    )
})
# Custom metrics path - local repository only
GetYamlPathCustomMetrics <- function() {
  test_path("qual_workflows/2_metrics_custom")
}

# Get cached workflows from remote repositories
metrics_workflow_path <- get_cached_workflows(
  strPackage = "gsm.kri",
  workflow_subdir = "2_metrics",
  branch = "main",
  force_update = FALSE,
  strNames = c("kri000[12]", "cou000[12]"))

mappings_workflow_path <- get_cached_workflows(
    strPackage = "gsm.mapping",
    workflow_subdir = "1_mappings",
    branch = "main",
    force_update = FALSE,
    strNames = c("^AE", "^SUBJ"))

# Workflow path helper functions
GetYamlPathMetrics <- function() {
  if (!is.null(metrics_workflow_path)) {
    return(metrics_workflow_path)
  } else {
    stop("No metrics workflows available. Check network connectivity.")
  }
}

GetYamlPathMappings <- function() {
  if (!is.null(mappings_workflow_path)) {
    return(mappings_workflow_path)
  } else {
    stop("No mapping workflows available. Check network connectivity.")
  }
}

# Data caching functions
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
  mappings_wf <- MakeWorkflowList(strPath = GetYamlPathMappings())

  ConsoleAppender <- log4r::console_appender(layout = gsm.core::cli_fmt)
  gsm.core::SetLogger(log4r::logger(
    threshold = "WARN",
    appenders = ConsoleAppender
  ))
  mapped_data <- RunWorkflows(mappings_wf, lData)
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
  mappings_wf <- MakeWorkflowList(strPath = GetYamlPathMappings())
  mapping_output <- map(mappings_wf, ~ .x$steps[[1]]$output) %>% unlist()

  saveRDS(mapping_output, cache_file)
  message("Cached mapping output updated successfully.")
  return(mapping_output)
}

# Get processed data using cached versions
mapped_data <- get_cached_mapped_data()
mapping_output <- get_cached_mapping_output()

# Create mappings_wf for compatibility
mappings_wf <- MakeWorkflowList(strPath = GetYamlPathMappings())

# Robust workflow runner that handles errors gracefully
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
      ~ gsm.core::RunStep(
        lStep = step,
        lData = lWorkflow$lData,
        lMeta = lWorkflow$meta
      )
    )()

    if (names(result0[!map_vec(result0, is.null)]) == "error") {
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

# Get relevant data for a workflow - wrapper for robust_runworkflow
get_data <- function(lWorkflow, data) {
  if ("spec" %in% names(lWorkflow)) lWorkflow <- list(lWorkflow)

  maps_needed_index <- map(lWorkflow, ~ names(.x$spec)) %>%
    unlist() %>%
    unique()

  maps_needed <- names(mapping_output[which(
    mapping_output %in% maps_needed_index
  )])

  # This code temporarily deals with column mismatches in gsm.core vs
  # gsm.mapping and should be removed when all packages are released.
  suppressWarnings(
    {
      mapped_needed_data <- RunWorkflows(mappings_wf[maps_needed], data)
    }
  )
  return(mapped_needed_data)
}

