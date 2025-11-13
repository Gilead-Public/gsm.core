# Cookbook

## Introduction

This vignette contains sample code showing how to use the Good
Statistical Monitoring `{gsm}` suite of packages using sample data from
[gsm.core](https://gilead-biostats.github.io/gsm.core). For more
information on the `{gsm}` suite of packages see the [package
homepage](https://gilead-biostats.github.io/gsm.core/).

## Setup and Installation

Run the following:

``` r
## Install devtools
install.packages('devtools')

## Install and load gsm
devtools::install_github("Gilead-BioStats/gsm.core", ref = "main")
library(gsm.core)

## Install and load gsm.mapping
devtools::install_github("Gilead-BioStats/gsm.mapping", ref = "main")
library(gsm.mapping)

## Install and load gsm.kri
devtools::install_github("Gilead-BioStats/gsm.kri", ref = "main")
library(gsm.kri)

## Install and load gsm.reporting
devtools::install_github("Gilead-BioStats/gsm.reporting", ref = "main")
library(gsm.kri)
```

## Example 1 - Adverse Events Metric - Scripted

This example uses the standard {gsm} analysis workflows to creates
site-level Adverse Event scripts. See the [Data Analysis
Vignette](https://gilead-biostats.github.io/gsm.core/articles/DataAnalysis.html)
for more detail.

- **Example 1.1** calculates the Site-level AE rates.
- **Example 1.2** adds a filter to include only Serious Adverse Events
  (SAEs) and implements pipes to run through the workflow.
- **Example 1.3** generates bar charts showing SAE rates and z-scores by
  study using [gsm.kri](https://github.com/Gilead-BioStats/gsm.kri).
- **Example 1.4** generates a scatter plot with confidence bound for SAE
  rates using [gsm.kri](https://github.com/Gilead-BioStats/gsm.kri).

``` r
#### Example 1.1 - Generate an Adverse Event Metric using the standard {gsm.core} workflow

dfInput <- Input_Rate(
  dfSubjects= gsm.core::lSource$Raw_SUBJ,
  dfNumerator= gsm.core::lSource$Raw_AE,
  dfDenominator = gsm.core::lSource$Raw_SUBJ,
  strSubjectCol = "subjid",
  strGroupCol = "invid",
  strNumeratorMethod= "Count",
  strDenominatorMethod= "Sum",
  strDenominatorCol= "timeonstudy"
)

dfTransformed <- Transform_Rate(dfInput)
dfAnalyzed <- Analyze_NormalApprox(dfTransformed, strType = "rate")
dfFlagged <- Flag_NormalApprox(dfAnalyzed, vThreshold = c(-3,-2,2,3))
dfSummarized <- Summarize(dfFlagged)

table(dfSummarized$Flag)

#### Example 1.2 - Make an SAE Metric by adding a filter.  Also works with pipes.

SAE_KRI <- Input_Rate(
  dfSubjects= gsm.core::lSource$Raw_SUBJ,
  dfNumerator= gsm.core::lSource$Raw_AE %>% filter(aeser=="Y"),
  dfDenominator = gsm.core::lSource$Raw_SUBJ,
  strSubjectCol = "subjid",
  strGroupCol = "invid",
  strNumeratorMethod= "Count",
  strDenominatorMethod= "Sum",
  strDenominatorCol= "timeonstudy"
) %>%
  Transform_Rate %>%
  Analyze_NormalApprox(strType = "rate") %>%
  Flag_NormalApprox(vThreshold = c(-3,-2,2,3)) %>%
  Summarize

table(SAE_KRI$Flag)

### Example 1.3 - Visualize Metric distribution using Bar Charts using provided htmlwidgets
library(gsm.kri)

labels <- list(
  Metric= "Serious Adverse Event Rate",
  Numerator= "Serious Adverse Events",
  Denominator= "Days on Study"
)

gsm.kri::Widget_BarChart(dfResults = SAE_KRI, lMetric=labels, strOutcome="Metric")
gsm.kri::Widget_BarChart(dfResults = SAE_KRI, lMetric=labels, strOutcome="Score")
gsm.kri::Widget_BarChart(dfResults = SAE_KRI, lMetric=labels, strOutcome="Numerator")

### Example 1.4 - Create Scatter plot with confidence bounds
dfBounds <- Analyze_NormalApprox_PredictBounds(SAE_KRI, vThreshold = c(-3,-2,2,3))
gsm.kri::Widget_ScatterPlot(SAE_KRI, lMetric = labels, dfBounds = dfBounds)
```

## Example 2 - Adverse Events Metrics - Workflow

This examples introduces YAML workflows to re-generate the same results
as in **Example 1** via a reusable pipeline. See the [Data Model
Vignette](https://gilead-biostats.github.io/gsm.core/articles/DataModel.html)
for more detail.

- **Example 2.1** runs the AE KRI workflow.
- **Example 2.2** updates the metadata to run country-level metrics.
- **Example 2.3** adds a filtering step to the workflow to generate the
  SAE metric.

``` r
library(gsm.mapping)
library(gsm.kri)

#### Example 2.1 - Configurable Adverse Event Workflow

# Define YAML workflow
AE_workflow <- read_yaml(text=
'meta:
  Type: Analysis
  ID: kri0001
  GroupLevel: Site
  Abbreviation: AE
  Metric: Adverse Event Rate
  Numerator: Adverse Events
  Denominator: Days on Study
  Model: Normal Approximation
  Score: Adjusted Z-Score
  AnalysisType: rate
  Threshold: -2,-1,2,3
  AccrualThreshold: 30
  AccrualMetric: Denominator
spec:
  Mapped_AE:
    subjid:
      type: character
  Mapped_SUBJ:
    subjid:
      type: character
    invid:
      type: character
    timeonstudy:
      type: integer
steps:
  - output: vThreshold
    name: ParseThreshold
    params:
      strThreshold: Threshold
  - output: Analysis_Input
    name: Input_Rate
    params:
      dfSubjects: Mapped_SUBJ
      dfNumerator: Mapped_AE
      dfDenominator: Mapped_SUBJ
      strSubjectCol: subjid
      strGroupCol: invid
      strGroupLevel: GroupLevel
      strNumeratorMethod: Count
      strDenominatorMethod: Sum
      strDenominatorCol: timeonstudy
  - output: Analysis_Transformed
    name: Transform_Rate
    params:
      dfInput: Analysis_Input
  - output: Analysis_Analyzed
    name: Analyze_NormalApprox
    params:
      dfTransformed: Analysis_Transformed
      strType: AnalysisType
  - output: Analysis_Flagged
    name: Flag_NormalApprox
    params:
      dfAnalyzed: Analysis_Analyzed
      vThreshold: vThreshold
      nAccrualThreshold: AccrualThreshold
      strAccrualMetric: AccrualMetric
  - output: Analysis_Summary
    name: Summarize
    params:
      dfFlagged: Analysis_Flagged
  - output: lAnalysis
    name: list
    params:
      ID: ID
      Analysis_Input: Analysis_Input
      Analysis_Transformed: Analysis_Transformed
      Analysis_Analyzed: Analysis_Analyzed
      Analysis_Flagged: Analysis_Flagged
      Analysis_Summary: Analysis_Summary
')

# Run the workflow
lMappingWorkflows <- MakeWorkflowList(
  strNames = c("AE", "SUBJ"),
  strPath = "workflow/1_mappings",
  strPackage = "gsm.mapping",
  bExact = TRUE
)
mappings_spec <- gsm.mapping::CombineSpecs(lMappingWorkflows)
lRawData <- gsm.mapping::Ingest(gsm.core::lSource, mappings_spec)
AE_data <-list(
  Mapped_SUBJ= lRawData$Raw_SUBJ,
  Mapped_AE= lRawData$Raw_AE
)
AE_KRI <- RunWorkflow(lWorkflow = AE_workflow, lData = AE_data)

# Create Barchart from workflow
Widget_BarChart(dfResults = AE_KRI$Analysis_Summary)

#### Example 2.2 - Run Country-Level Metric
AE_country_workflow <- AE_workflow
AE_country_workflow$meta$GroupLevel <- "Country"
AE_country_workflow$steps[[2]]$params$strGroupCol <- "country"

AE_country_KRI <- RunWorkflow(lWorkflow = AE_country_workflow, lData = AE_data)
gsm.kri::Widget_BarChart(dfResults = AE_country_KRI$Analysis_Summary, lMetric = AE_country_workflow$meta)

#### Example 2.3 - Create SAE workflow

# Tweak AE workflow metadata
SAE_workflow <- AE_workflow
SAE_workflow$meta$File <- "SAE_KRI"
SAE_workflow$meta$Metric <- "Serious Adverse Event Rate"
SAE_workflow$meta$Numerator <- "Serious Adverse Events"

# Add a step to filter out non-serious AEs `RunQuery`
filterStep <- list(list(
  name = "RunQuery",
  output = "Mapped_AE",
  params= list(
    df= "Mapped_AE",
    strQuery = "SELECT * FROM df WHERE aeser = 'Y'"
  ))
)
SAE_workflow$steps <- SAE_workflow$steps %>% append(filterStep, after=0)

# Run the updated workflow
SAE_KRI <- RunWorkflow(lWorkflow = SAE_workflow, lData = AE_data )
gsm.kri::Widget_BarChart(dfResults = SAE_KRI$Analysis_Summary, lMetric = SAE_workflow$meta)
```

## Example 3 - Study-Level Reporting Workflows

This example extends the previous examples to generate charts and
reports for multiple KRIs. See the [Data Reporting
Vignette](https://gilead-biostats.github.io/gsm.reporting/articles/DataReporting.html)
for more detail.

- **Example 3.1** steps through several workflows to generate a report
  for all 12 standard site-level KRIs.
- **Example 3.2** automates data ingestion using `gsm.mapping::Ingest()`
  and `gsm.mapping::CombineSpecs()`.
- **Example 3.3** generates a report using
  [gsm.kri](https://github.com/Gilead-BioStats/gsm.kri) incorporating
  multiple timepoints using the sample `reporting` data saved as part of
  [gsm.core](https://gilead-biostats.github.io/gsm.core).

``` r
library(gsm.core)
library(gsm.mapping)
library(gsm.kri)
library(gsm.reporting)
library(dplyr)

#### 3.1 - Create a KRI Report using 13 standard metrics in a step-by-step workflow

core_mappings <- c("AE", "COUNTRY", "DATACHG", "DATAENT", "ENROLL", "LB", "PK", "VISIT",
                   "PD", "QUERY", "STUDY", "STUDCOMP", "SDRGCOMP", "SITE", "SUBJ")

# Step 0 - Create Raw Data from Source Data
lRaw <- list(
  Raw_SUBJ = gsm.core::lSource$Raw_SUBJ,
  Raw_AE = gsm.core::lSource$Raw_AE,
  Raw_PD = gsm.core::lSource$Raw_PD %>%
    rename(subjid = subjectenrollmentnumber),
  Raw_PK = gsm.core::lSource$Raw_PK %>%
    rename(visit = foldername),
  Raw_LB = gsm.core::lSource$Raw_LB,
  Raw_STUDCOMP = gsm.core::lSource$Raw_STUDCOMP %>%
    select(subjid, compyn),
  Raw_SDRGCOMP = gsm.core::lSource$Raw_SDRGCOMP,
  Raw_DATACHG = gsm.core::lSource$Raw_DATACHG %>%
    rename(subject_nsv = subjectname),
  Raw_DATAENT = gsm.core::lSource$Raw_DATAENT %>%
    rename(subject_nsv = subjectname),
  Raw_QUERY = gsm.core::lSource$Raw_QUERY %>%
    rename(subject_nsv = subjectname),
  Raw_ENROLL = gsm.core::lSource$Raw_ENROLL,
  Raw_SITE = gsm.core::lSource$Raw_SITE %>%
    rename(studyid = protocol) %>%
    rename(invid = pi_number) %>%
    rename(InvestigatorFirstName = pi_first_name) %>%
    rename(InvestigatorLastName = pi_last_name) %>%
    rename(City = city) %>%
    rename(State = state) %>%
    rename(Country = country) %>%
    rename(Status = site_status),
  Raw_STUDY = gsm.core::lSource$Raw_STUDY %>%
    rename(studyid = protocol_number) %>%
    rename(Status = status),
  Raw_VISIT = gsm.core::lSource$Raw_VISIT %>%
    mutate(visit_folder = foldername) %>%
    rename(visit = foldername)
)

# Step 1 - Create Mapped Data Layer - filter, aggregate and join raw data to create mapped data layer
mappings_wf <- gsm.core::MakeWorkflowList(strNames = core_mappings, strPath = "workflow/1_mappings", strPackage = "gsm.mapping")
mapped <- gsm.core::RunWorkflows(mappings_wf, lRaw)

# Step 2 - Create Metrics - calculate metrics using mapped data
metrics_wf <- gsm.core::MakeWorkflowList(strPath = "workflow/2_metrics", strPackage = "gsm.kri")
analyzed <- gsm.core::RunWorkflows(metrics_wf, mapped)

# Step 3 - Create Reporting Layer - create reports using metrics data
reporting_wf <- gsm.core::MakeWorkflowList(strPath = "workflow/3_reporting", strPackage = "gsm.reporting")
reporting <- gsm.core::RunWorkflows(reporting_wf, c(mapped, list(lAnalyzed = analyzed, lWorkflows = metrics_wf)))

# Step 4 - Create KRI Reports - create KRI report using reporting data
module_wf <- gsm.core::MakeWorkflowList(strPath = "workflow/4_modules", strPackage = "gsm.kri")
lReports <- gsm.core::RunWorkflows(module_wf, reporting)

#### 3.2 - Automate data ingestion using Ingest() and CombineSpecs()
# Step 0 - Data Ingestion - standardize tables/columns names
mappings_wf <- gsm.core::MakeWorkflowList(strNames = core_mappings, strPath = "workflow/1_mappings", strPackage = "gsm.mapping")
mappings_spec <- gsm.mapping::CombineSpecs(mappings_wf)
lRaw <- gsm.mapping::Ingest(gsm.core::lSource, mappings_spec)

# Step 1 - Create Mapped Data Layer - filter, aggregate and join raw data to create mapped data layer
mapped <- gsm.core::RunWorkflows(mappings_wf, lRaw)

# Step 2 - Create Metrics - calculate metrics using mapped data
metrics_wf <- gsm.core::MakeWorkflowList(strPath = "workflow/2_metrics", strPackage = "gsm.kri")
analyzed <- gsm.core::RunWorkflows(metrics_wf, mapped)

# Step 3 - Create Reporting Layer - create reports using metrics data
reporting_wf <- gsm.core::MakeWorkflowList(strPath = "workflow/3_reporting", strPackage = "gsm.reporting")
reporting <- gsm.core::RunWorkflows(reporting_wf, c(mapped, list(lAnalyzed = analyzed, lWorkflows = metrics_wf)))

# Step 4 - Create KRI Report - create KRI report using reporting data
module_wf <- gsm.core::MakeWorkflowList(strPath = "workflow/4_modules", strPackage = "gsm.kri")
lReports <- gsm.core::RunWorkflows(module_wf, reporting)


#### 3.3 Site-Level KRI Report with multiple SnapshotDate
# Below relies on the clindata stuff, do we need to rerun/rewrite reporting datasets?
lCharts <- gsm.kri::MakeCharts(
  dfResults = gsm.core::reportingResults,
  dfGroups = gsm.core::reportingGroups,
  dfMetrics = gsm.core::reportingMetrics,
  dfBounds = gsm.core::reportingBounds
)

kri_report_path <- gsm.kri::Report_KRI(
  lCharts = lCharts,
  dfResults =  gsm.kri::FilterByLatestSnapshotDate(reportingResults),
  dfGroups =  gsm.core::reportingGroups,
  dfMetrics = gsm.core::reportingMetrics
)

#### 3.4 Reporting Results with Changes from previous snapshot

# Prepare historical data
historical <- gsm.core::reportingResults %>% filter(SnapshotDate == "2025-03-01")

# Re-run reporting model and KRI report with historical data
reporting_long <- gsm.core::RunWorkflows(reporting_wf, c(mapped, list(lAnalyzed = analyzed, Reporting_Results_Longitudinal = historical, lWorkflows = metrics_wf)))
lReports_long <- gsm.core::RunWorkflows(module_wf, reporting_long)
```

## Example 4 - Reading and Writing from External Data Sources

This example extends the previous examples to use data from an external
source, by specifying `LoadData()` and `SaveData()` functions to be used
in
[`RunWorkflows()`](https://gilead-biostats.github.io/gsm.core/dev/reference/RunWorkflows.md)
`lConfig` argument.

``` r
devtools::load_all()

LoadData <- function(lWorkflow, lConfig, lData = NULL) {
  lData <- lData
    purrr::imap(
        lWorkflow$spec,
        ~ {
            input <- lConfig$Domains[[ .y ]]

            if (is.data.frame(input)) {
                data <- input
            } else if (is.function(input)) {
                data <- input()
            } else if (is.character(input)) {
                data <- read.csv(input)
            } else {
                cli::cli_abort("Invalid data source: {input}.")
            }

            lData[[ .y ]] <<- (ApplySpec(data, .x))
        }
    )
    return(lData)
}

SaveData <- function(lWorkflow, lConfig) {
    domain <- paste0(lWorkflow$meta$Type, '_', lWorkflow$meta$ID)
    cli::cli_alert_info(domain)

    if (exists(domain, lConfig$Domains)) {
        output <- lConfig$Domains[[ domain ]]
        cli::cli_alert_info(output)

        cli::cli_alert_info(
            'Saving output of `lWorkflow` to `{output}`.'
        )

        write.csv(
            lWorkflow$lResult,
            output
        )
    } else {
        cli::cli_alert_info(
            '{domain} not found.'
        )
    }
}

lConfig <- list(
    LoadData = LoadData,
    SaveData = SaveData,
    Domains = c(
        Raw_STUDY = function() { gsm.core::lSource$Raw_STUDY },
        Raw_SITE = function() { gsm.core::lSource$Raw_SITE },
        Raw_PD = function() { gsm.core::lSource$Raw_PD },

        Raw_SUBJ = function() { gsm.core::lSource$Raw_SUBJ },
        Raw_ENROLL = function() { gsm.core::lSource$Raw_ENROLL },
        Raw_SDRGCOMP = function() { gsm.core::lSource$Raw_SDRGCOMP },
        Raw_STUDCOMP = function() { gsm.core::lSource$Raw_STUDCOMP },
        Raw_LB = function() { gsm.core::lSource$Raw_LB },
        Raw_AE = function() { gsm.core::lSource$Raw_AE },

        Raw_DATAENT = function() { gsm.core::lSource$Raw_DATAENT },
        Raw_DATACHG = function() { gsm.core::lSource$Raw_DATACHG },
        Raw_QUERY = function() { gsm.core::lSource$Raw_QUERY },

        Mapped_STUDY = file.path(tempdir(), 'mapped-study.csv'),
        Mapped_SITE = file.path(tempdir(), 'mapped-site.csv'),
        Mapped_COUNTRY = file.path(tempdir(), 'mapped-country.csv'),
        Mapped_PD = file.path(tempdir(), 'mapped-pd.csv'),

        Mapped_SUBJ = file.path(tempdir(), 'mapped-subj.csv'),
        Mapped_ENROLL = file.path(tempdir(), 'mapped-enroll.csv'),
        Mapped_SDRGCOMP = file.path(tempdir(), 'mapped-sdrgcomp.csv'),
        Mapped_STUDCOMP = file.path(tempdir(), 'mapped-studcomp.csv'),
        Mapped_LB = file.path(tempdir(), 'mapped-lb.csv'),
        Mapped_AE = file.path(tempdir(), 'mapped-ae.csv'),

        Mapped_DATAENT = file.path(tempdir(), 'mapped-dataent.csv'),
        Mapped_DATACHG = file.path(tempdir(), 'mapped-datachg.csv'),
        Mapped_QUERY = file.path(tempdir(), 'mapped-query.csv')
    )
)

core_mappings <- c("AE", "COUNTRY", "DATACHG", "DATAENT", "ENROLL", "LB",
                   "PD", "QUERY", "STUDY", "STUDCOMP", "SDRGCOMP", "SITE", "SUBJ")

lMappedData <- RunWorkflows(
    MakeWorkflowList(strNames = core_mappings, strPath = 'workflow/1_mappings', strPackage = "gsm.mapping"),
    lConfig = lConfig
)
```
