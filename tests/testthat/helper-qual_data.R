library(gsm.mapping)
library(gsm.reporting)

set.seed(123)

## Declare all the data
lSource <- gsm.core::lSource

# Step 0 - Data Ingestion - standardize tables/columns names
lData <- list(
  Raw_SUBJ = lSource$Raw_SUBJ,
  Raw_AE = lSource$Raw_AE,
  Raw_PD = lSource$Raw_PD %>%
    rename(subjid = subjectenrollmentnumber) %>%
    rename(dvdecod = crocategory) %>%
    rename(dvterm = description) %>%
    rename(dvdtm = deviationdate),
  Raw_LB = lSource$Raw_LB,
  Raw_STUDCOMP = lSource$Raw_STUDCOMP,
  Raw_SDRGCOMP = lSource$Raw_SDRGCOMP %>%
    mutate(phase = as.character(phase)),
  Raw_DATACHG = lSource$Raw_DATACHG %>%
    rename(subject_nsv = subjectname),
  Raw_DATAENT = lSource$Raw_DATAENT %>%
    rename(subject_nsv = subjectname),
  Raw_QUERY = lSource$Raw_QUERY %>%
    rename(subject_nsv = subjectname),
  Raw_ENROLL = lSource$Raw_ENROLL,
  Raw_SITE = lSource$Raw_SITE %>%
    rename(studyid = protocol) %>%
    rename(invid = pi_number) %>%
    rename(InvestigatorFirstName = pi_first_name) %>%
    rename(InvestigatorLastName = pi_last_name) %>%
    rename(City = city) %>%
    rename(State = state) %>%
    rename(Country = country),
  Raw_STUDY = lSource$Raw_STUDY %>%
    rename(studyid = protocol_number),
  Raw_PK = lSource$Raw_PK %>%
    rename(visit = foldername),
  Raw_IE = lSource$Raw_IE,
  Raw_VISIT = lSource$Raw_VISIT %>%
    rename(visit = foldername)
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

## custom kris path instead of inst/workflow
GetYamlPathCustomMetrics <- function() {
  test_path("qual_workflows/2_metrics_custom")
}

## default kri path
GetDefaultKRIPath <- function() {
  test_path("qual_workflows/2_metrics")
}

## Get Mapped data
mappings_wf <- MakeWorkflowList(
  strPath = test_path("qual_workflows/1_mappings")
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

mapping_output <- map(mappings_wf, ~ .x$steps[[1]]$output) %>% unlist()

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
