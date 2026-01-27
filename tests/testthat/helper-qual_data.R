set.seed(123)

## Declare all the data
lSource <- gsm.core::lSource

# Step 0 - Data Ingestion - standardize tables/columns names
lData <- list(
  Raw_SUBJ = lSource$Raw_SUBJ,
  Raw_AE = lSource$Raw_AE
)

## Data with missing values (15% NA's)

## ONLY USED IN T2_2
lData_missing_values <- map(lData, function(df) {
  df %>%
    mutate(
      across(
        !contains("GroupID"),
        ~ replace(., sample(row_number(), size = .15 * n()), NA)
      )
    )
})
#
## custom metrics path - these are local to this repository
GetYamlPathCustomMetrics <- function() {
  # Custom metrics are generated locally and should not be pulled from remote
  test_path("qual_workflows/2_metrics_custom")
}

## Get cached matrics workflows from gsm.kri
metrics_workflow_path <- get_cached_workflows(
  strPackage = "gsm.kri",
  workflow_subdir = "2_metrics",
  branch = "main",
  force_update = FALSE,
  strNames = c("kri000[12]", "cou000[12]"))

## Get cached mapping workflows from gsm.mapping
mappings_workflow_path <- get_cached_workflows(
    strPackage = "gsm.mapping",
    workflow_subdir = "1_mappings",
    branch = "main",
    force_update = FALSE,
    strNames = c("^AE", "^SUBJ"))

## Helper functions to get workflow paths with fallbacks
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

## Helper functions for caching processed data
get_data_cache_dir <- function() {
  cache_dir <- file.path(tools::R_user_dir("gsm", "cache"), "processed_data")
  if (!dir.exists(cache_dir)) {
    dir.create(cache_dir, recursive = TRUE)
  }
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
      
      # Use cache if it's newer than the workflow files
      if (cache_time > newest_workflow) {
        message("Using cached mapped data.")
        return(readRDS(cache_file))
      }
    }
  }
  
  # Generate fresh data
  message("Updating cached mapped data...")
  mappings_wf <- MakeWorkflowList(
    strPath = GetYamlPathMappings()
  )
  
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
  
  # Save to cache
  saveRDS(mapped_data, cache_file)
  message("Cached mapped data updated successfully.")
  return(mapped_data)
}

get_cached_mapping_output <- function(force_refresh = FALSE) {
  cache_dir <- get_data_cache_dir()
  cache_file <- file.path(cache_dir, "mapping_output.rds")
  
  if (!force_refresh && file.exists(cache_file)) {
    # Check if workflows have been updated since cache was created
    workflow_dir <- GetYamlPathMappings()
    workflow_files <- list.files(workflow_dir, pattern = "\\.ya?ml$", full.names = TRUE)
    
    if (length(workflow_files) > 0) {
      newest_workflow <- max(file.mtime(workflow_files))
      cache_time <- file.mtime(cache_file)
      
      # Use cache if it's newer than the workflow files
      if (cache_time > newest_workflow) {
        message("Using cached mapping output.")
        return(readRDS(cache_file))
      }
    }
  }
  
  # Generate fresh data
  message("Updating cached mapping output...")
  mappings_wf <- MakeWorkflowList(
    strPath = GetYamlPathMappings()
  )
  
  mapping_output <- map(mappings_wf, ~ .x$steps[[1]]$output) %>% unlist()
  
  # Save to cache
  saveRDS(mapping_output, cache_file)
  message("Cached mapping output updated successfully.")
  return(mapping_output)
}

## Get Mapped data - now using cached version
mapped_data <- get_cached_mapped_data()

mapping_output <- get_cached_mapping_output()

## Create mappings_wf for compatibility with existing tests
mappings_wf <- MakeWorkflowList(
  strPath = GetYamlPathMappings()
)

# Robust version of Runworkflow no config that will always run even with errors,
# and can be specified for specific steps in workflow to run
robust_runworkflow <- function(
  lWorkflow,
  lData,
  steps = seq(lWorkflow$steps),
  bReturnResult = TRUE,
  bKeepInputData = TRUE
) {
  # Create a unique identifier for the workflow
  uid <- paste0(lWorkflow$meta$Type, "_", lWorkflow$meta$ID)
  # cli::cli_h1("Initializing `{uid}` Workflow")

  # check that the workflow has steps
  # if (length(lWorkflow$steps) == 0) {
  #   cli::cli_alert("Workflow `{uid}` has no `steps` property.")
  # }

  # if (!"meta" %in% names(lWorkflow)) {
  #   cli::cli_alert("Workflow `{uid}` has no `meta` property.")
  # }

  lWorkflow$lData <- lData

  # If the workflow has a spec, check that the data and spec are compatible
  if ("spec" %in% names(lWorkflow)) {
    # cli::cli_h3("Checking data against spec")
    CheckSpec(lData, lWorkflow$spec)
  } else {
    lWorkflow$spec <- NULL
    # cli::cli_h3(
    #   "No spec found in workflow. Proceeding without checking data."
    # )
  }

  if (length(steps) > 1) {
    lWorkflow$steps <- lWorkflow$steps[steps]
  } else if (length(steps) == 1) {
    lWorkflow$steps <- list(lWorkflow$steps[[steps]])
  }

  # Run through each steps in lWorkflow$workflow
  stepCount <- 1
  for (steps in lWorkflow$steps) {
    # cli::cli_h2(paste0(
    #   "Workflow steps ",
    #   stepCount,
    #   " of ",
    #   length(lWorkflow$steps),
    #   ": `",
    #   steps$name,
    #   "`"
    # ))

    result0 <- purrr::safely(
      ~ gsm.core::RunStep(
        lStep = steps,
        lData = lWorkflow$lData,
        lMeta = lWorkflow$meta
      )
    )()
    if (names(result0[!map_vec(result0, is.null)]) == "error") {
      cli::cli_alert_danger(paste0(
        "Error:`",
        result0$error$message,
        "`:",
        " error message stored as result"
      ))
      result1 <- result0$error$message
    } else {
      result1 <- result0$result
    }

    lWorkflow$lData[[steps$output]] <- result1
    lWorkflow$lResult <- result1

    if (is.data.frame(result1)) {
      # cli::cli_h3(
      #   "{paste(dim(result1),collapse='x')} data.frame saved as `lData${steps$output}`."
      # )
    } else {
      # cli::cli_h3(
      #   "{typeof(result1)} of length {length(result1)} saved as `lData${steps$output}`."
      # )
    }

    stepCount <- stepCount + 1
  }

  # Return the result of the last step (the default) or the full workflow

  if (!bKeepInputData) {
    outputs <- lWorkflow$steps %>% purrr::map_chr(~ .x$output)
    lWorkflow$lData <- lWorkflow$lData[outputs]
    # cli::cli_alert_info("Returning workflow outputs: {names(lWorkflow$lData)}")
  } else {
    # cli::cli_alert_info("Returning workflow inputs and outputs: {names(lWorkflow$lData)}")
  }

  if (bReturnResult) {
    return(lWorkflow$lData)
  } else {
    return(lWorkflow)
  }
}

# get only the relevant data for a workflow to speed up mapping
# Just a fancy wrapper for robust_runworkflow
get_data <- function(lWorkflow, data) {
  if ("spec" %in% names(lWorkflow)) {
    lWorkflow <- list(lWorkflow)
  }
  maps_needed_index <- map(lWorkflow, ~ names(.x$spec)) %>%
    unlist() %>%
    unique()
  maps_needed <- names(mapping_output[which(
    mapping_output %in% maps_needed_index
  )])
  mapped_needed_data <- RunWorkflows(mappings_wf[maps_needed], data)
  return(mapped_needed_data)
}

