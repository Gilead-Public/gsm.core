pak::pak('Gilead-BioStats/gsm.mapping@dev')
pak::pak('Gilead-BioStats/gsm.core@dev')
pak::pak('Gilead-BioStats/gsm.kri@dev')

library(gsm.core)
library(gsm.mapping)
library(gsm.datasim)
library(gsm.kri)
library(gsm.reporting)
library(gsm.qtl)
library(dplyr)
library(stringr)
set.seed(1234)

core_mappings <- c("AE", "COUNTRY", "DATACHG", "DATAENT", "ENROLL", "LB", "VISIT", "Death", "OverallResponse", "Randomization",
                   "PD", "PK", "QUERY", "STUDY", "STUDCOMP", "SDRGCOMP", "SITE", "SUBJ", "IE", "EXCLUSION")

basic_sim <- gsm.datasim::generate_rawdata_for_single_study(
  SnapshotCount = 3,
  SnapshotWidth = "months",
  ParticipantCount = 1000,
  SiteCount = 150,
  StudyID = "AA-AA-000-0000",
  workflow_path = "workflow/1_mappings",
  mappings = core_mappings,
  package = "gsm.mapping",
  desired_specs = NULL
)
basic_sim[[1]]$Raw_SITE$site_status <- "Active"
basic_sim[[2]]$Raw_SITE$site_status <- "Active"
basic_sim[[3]]$Raw_SITE$site_status <- "Active"

## Run Data pipeline for each snapshot
analyzed <- list()
reporting <- list()
dates <- as.Date(c("2025-02-01", "2025-03-01", "2025-04-01"))

mappings_wf <- gsm.core::MakeWorkflowList(strNames = core_mappings, strPath = "workflow/1_mappings", strPackage = "gsm.mapping")
mappings_spec <- gsm.mapping::CombineSpecs(mappings_wf)
metrics_wf <- c(
  gsm.core::MakeWorkflowList(strPath = "workflow/2_metrics", strPackage = "gsm.kri"),
  gsm.core::MakeWorkflowList(strPath = "workflow/2_metrics", strPackage = "gsm.qtl")
)
reporting_wf <- gsm.core::MakeWorkflowList(strPath = "workflow/3_reporting", strPackage = "gsm.reporting")

for(snap in seq_along(basic_sim)){
  lSource <- basic_sim[[snap]]

  lRaw <- gsm.mapping::Ingest(lSource, mappings_spec)

  # Step 1 - Create Mapped Data Layer - filter, aggregate and join raw data to create mapped data layer
  mapped <- gsm.core::RunWorkflows(mappings_wf, lRaw)

  # Step 2 - Create Metrics - calculate metrics using mapped data
  analyzed[[snap]] <- gsm.core::RunWorkflows(metrics_wf, c(mapped, list(lWorkflows = metrics_wf)))

  # Step 3 - Create Reporting Layer - create reports using metrics data
  reporting[[snap]] <- gsm.core::RunWorkflows(reporting_wf, c(mapped, list(lAnalyzed = analyzed[[snap]], lWorkflows = metrics_wf)))
  reporting[[snap]]$Reporting_Results$SnapshotDate = dates[snap]
  reporting[[snap]]$Reporting_Bounds$SnapshotDate = dates[snap]
}

all_reportingResults <- do.call(bind_rows, lapply(reporting, function(x) x$Reporting_Results))
all_reportingGroups <- reporting[[snap]]$Reporting_Groups
all_reportingBounds <- do.call(bind_rows, lapply(reporting, function(x) x$Reporting_Bounds))
all_reportingMetrics <- reporting[[snap]]$Reporting_Metrics

#save site and country data separately
lReporting_site <- list()
lReporting_country <- list()
lReporting_study <- list()

lReporting_site$Reporting_Results <- all_reportingResults %>%
  filter(GroupLevel %in% c("Site"))
lReporting_site$Reporting_Groups <- all_reportingGroups %>%
  filter(GroupLevel %in% c("Study", "Site"))
lReporting_site$Reporting_Bounds <-  all_reportingBounds %>%
  filter(stringr::str_detect(MetricID, "Analysis_kri"))
lReporting_site$Reporting_Metrics <- all_reportingMetrics %>%
  filter(GroupLevel %in% c("Site"))

lReporting_country$Reporting_Results <- all_reportingResults %>%
  filter(GroupLevel=="Country")
lReporting_country$Reporting_Groups <- all_reportingGroups %>%
  filter(GroupLevel%in% c("Study","Country"))
lReporting_country$Reporting_Bounds <- all_reportingBounds %>%
  filter(stringr::str_detect(MetricID, "Analysis_cou"))
lReporting_country$Reporting_Metrics <- all_reportingMetrics %>%
  filter(GroupLevel=="Country")

lReporting_study$Reporting_Results <- all_reportingResults %>%
  filter(GroupLevel=="Study")
lReporting_study$Reporting_Groups <- all_reportingGroups %>%
  filter(GroupLevel%in% c("Study"))
lReporting_study$Reporting_Bounds <- all_reportingBounds %>%
  filter(stringr::str_detect(MetricID, "Analysis_qtl"))
lReporting_study$Reporting_Metrics <- all_reportingMetrics %>%
  filter(GroupLevel=="Study")

## test out the data on a report
# wf_report_site <- MakeWorkflowList(strNames = "report_kri_site", strPackage = "gsm.kri")
# lReports_site <- RunWorkflows(wf_report_site, lReporting_site)
# wf_report_country <- MakeWorkflowList(strNames = "report_kri_country")
# lReports_country <- RunWorkflows(wf_report_country, lReporting_country)

# Output Raw data from last snapshot as gsm.core::lSource
lSource <- basic_sim[[3]]
usethis::use_data(lSource, overwrite = TRUE)

# write CSVs
# analysis data
## site
write.csv(file = "data-raw/analyticsSummary.csv",
          x = analyzed[[3]]$Analysis_kri0001$Analysis_Summary,
          row.names = F)
write.csv(file = "data-raw/analyticsInput.csv",
          x = analyzed[[3]]$Analysis_kri0001$Analysis_Input,
          row.names = F)

## country
write.csv(file = "data-raw/analyticsSummary_country.csv",
          x = analyzed[[3]]$Analysis_cou0001$Analysis_Summary,
          row.names = F)
write.csv(file = "data-raw/analyticsInput_country.csv",
          x = analyzed[[3]]$Analysis_cou0001$Analysis_Input,
          row.names = F)


# reporting data
## site
write.csv(file = "data-raw/reportingGroups.csv",
          x = lReporting_site$Reporting_Groups,
          row.names = F)
write.csv(file = "data-raw/reportingBounds.csv",
          x = lReporting_site$Reporting_Bounds,
          row.names = F)
write.csv(file = "data-raw/reportingMetrics.csv",
          x = lReporting_site$Reporting_Metrics,
          row.names = F)
write.csv(file = "data-raw/reportingResults.csv",
          x = lReporting_site$Reporting_Results,
          row.names = F)

##country
write.csv(file = "data-raw/reportingGroups_country.csv",
          x = lReporting_country$Reporting_Groups,
          row.names = F)
write.csv(file = "data-raw/reportingBounds_country.csv",
          x = lReporting_country$Reporting_Bounds,
          row.names = F)
write.csv(file = "data-raw/reportingMetrics_country.csv",
          x = lReporting_country$Reporting_Metrics,
          row.names = F)
write.csv(file = "data-raw/reportingResults_country.csv",
          x = lReporting_country$Reporting_Results,
          row.names = F)

##study
write.csv(file = "data-raw/reportingGroups_study.csv",
          x = lReporting_study$Reporting_Groups,
          row.names = F)
write.csv(file = "data-raw/reportingBounds_study.csv",
          x = lReporting_study$Reporting_Bounds,
          row.names = F)
write.csv(file = "data-raw/reportingMetrics_study.csv",
          x = lReporting_study$Reporting_Metrics,
          row.names = F)
write.csv(file = "data-raw/reportingResults_study.csv",
          x = lReporting_study$Reporting_Results,
          row.names = F)
