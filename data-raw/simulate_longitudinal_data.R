# pak::pak('Gilead-Public/gsm.datasim@dev')
# pak::pak('Gilead-Public/gsm.mapping@dev')
# pak::pak('Gilead-Public/gsm.kri@dev')
# pak::pak('Gilead-Public/gsm.reporting@dev')
# pak::pak('Gilead-Public/gsm.qtl@dev')
# pak::pak('Gilead-Public/gsm.core@dev')

library(gsm.core)
library(gsm.mapping)
library(gsm.datasim)
library(gsm.kri)
library(gsm.reporting)
library(gsm.qtl)
library(dplyr)
library(stringr)

logger::log_threshold(logger::ERROR)
# Seed moved off 1234 to avoid a Raw_SITE site ID collision
# (Gilead-Public/gsm.datasim#167).
set.seed(1235)

core_mappings <- c(
  "AE",
  "COUNTRY",
  "DATACHG",
  "DATAENT",
  "ENROLL",
  "LB",
  "VISIT",
  "Death",
  "OverallResponse",
  "Randomization",
  "PD",
  "PK",
  "QUERY",
  "STUDY",
  "STUDCOMP",
  "SDRGCOMP",
  "SITE",
  "SUBJ",
  "IE",
  "EXCLUSION",
  "VS"
)

# Analytics and reporting are left off here; this script drives those steps
# itself via RunWorkflows() below.
basic_study <- gsm.datasim::create_longitudinal_study(
  study_id = "AA-AA-000-0000",
  participants = 1000,
  sites = 150,
  snapshots = 3,
  interval = "1 month",
  domains = core_mappings,
  run_analytics = FALSE,
  run_reporting = FALSE
)
basic_sim <- basic_study$raw_data
basic_sim[[1]]$Raw_SITE$site_status <- "Active"
basic_sim[[2]]$Raw_SITE$site_status <- "Active"
basic_sim[[3]]$Raw_SITE$site_status <- "Active"

## Run Data pipeline for each snapshot
analyzed <- list()
reporting <- list()
dates <- as.Date(c("2025-02-01", "2025-03-01", "2025-04-01"))

# Mapped_IPNS is derived from Mapped_SUBJ rather than a raw domain, so it joins
# the workflow list but not the raw-data generation above.
mapping_workflows <- c(core_mappings, "IPNS")
mappings_wf <- workr::MakeWorkflowList(
  strNames = mapping_workflows,
  strPath = "workflow/1_mappings",
  strPackage = "gsm.mapping"
)
mappings_spec <- gsm.mapping::CombineSpecs(mappings_wf)
metrics_wf <- c(
  workr::MakeWorkflowList(
    strPath = "workflow/2_metrics",
    strPackage = "gsm.kri"
  ),
  # Inactive metrics stay out of study runs and risk scores, but are bundled
  # so the example reports show them.
  workr::MakeWorkflowList(
    strNames = I(c("kri0007", "cou0007")),
    strPath = "workflow/2_metrics",
    strPackage = "gsm.kri",
    bActiveOnly = FALSE
  ),
  workr::MakeWorkflowList(
    strPath = "workflow/2_metrics",
    strPackage = "gsm.qtl"
  )
)
reporting_wf <- workr::MakeWorkflowList(
  strPath = "workflow/3_reporting",
  strPackage = "gsm.reporting"
)

for (snap in seq_along(basic_sim)) {
  lSource <- basic_sim[[snap]]

  lRaw <- gsm.mapping::Ingest(lSource, mappings_spec)

  # Step 1 - Create Mapped Data Layer - filter, aggregate and join raw data to create mapped data layer
  mapped <- workr::RunWorkflows(mappings_wf, lRaw)

  # Step 2 - Create Metrics - calculate metrics using mapped data
  analyzed[[snap]] <- workr::RunWorkflows(
    metrics_wf,
    c(mapped, list(lWorkflows = metrics_wf))
  )

  # Step 3 - Create Reporting Layer - create reports using metrics data
  reporting[[snap]] <- workr::RunWorkflows(
    reporting_wf,
    c(mapped, list(lAnalyzed = analyzed[[snap]], lWorkflows = metrics_wf))
  )
  reporting[[snap]]$Reporting_Results$SnapshotDate <- dates[snap]
  reporting[[snap]]$Reporting_Bounds$SnapshotDate <- dates[snap]
}

all_reportingResults <- do.call(
  bind_rows,
  lapply(reporting, function(x) x$Reporting_Results)
)
all_reportingGroups <- reporting[[snap]]$Reporting_Groups
all_reportingBounds <- do.call(
  bind_rows,
  lapply(reporting, function(x) x$Reporting_Bounds)
)
all_reportingMetrics <- reporting[[snap]]$Reporting_Metrics

#save site and country data separately
lReporting_site <- list()
lReporting_country <- list()
lReporting_study <- list()

lReporting_site$Reporting_Results <- all_reportingResults %>%
  filter(GroupLevel %in% c("Site"))
lReporting_site$Reporting_Groups <- all_reportingGroups %>%
  filter(GroupLevel %in% c("Study", "Site"))
lReporting_site$Reporting_Bounds <- all_reportingBounds %>%
  filter(stringr::str_detect(MetricID, "Analysis_kri"))
lReporting_site$Reporting_Metrics <- all_reportingMetrics %>%
  filter(GroupLevel %in% c("Site"))

lReporting_country$Reporting_Results <- all_reportingResults %>%
  filter(GroupLevel == "Country")
lReporting_country$Reporting_Groups <- all_reportingGroups %>%
  filter(GroupLevel %in% c("Study", "Country"))
lReporting_country$Reporting_Bounds <- all_reportingBounds %>%
  filter(stringr::str_detect(MetricID, "Analysis_cou"))
lReporting_country$Reporting_Metrics <- all_reportingMetrics %>%
  filter(GroupLevel == "Country")

lReporting_study$Reporting_Results <- all_reportingResults %>%
  filter(GroupLevel == "Study")
lReporting_study$Reporting_Groups <- all_reportingGroups %>%
  filter(GroupLevel %in% c("Study"))
lReporting_study$Reporting_Bounds <- all_reportingBounds %>%
  filter(stringr::str_detect(MetricID, "Analysis_qtl"))
lReporting_study$Reporting_Metrics <- all_reportingMetrics %>%
  filter(GroupLevel == "Study")

## test out the data on a report
# wf_report_site <- MakeWorkflowList(strNames = "report_kri_site", strPackage = "gsm.kri")
# lReports_site <- RunWorkflows(wf_report_site, lReporting_site)
# wf_report_country <- MakeWorkflowList(strNames = "report_kri_country")
# lReports_country <- RunWorkflows(wf_report_country, lReporting_country)

# Output Raw data from last snapshot as gsm.core::lSource
lSource <- basic_sim[[3]]

# The premature-death report (gsm.kri#304) reads AE outcome, relatedness and
# death flag from lSource. They need gsm.mapping#135 and gsm.datasim#142 on dev;
# stop rather than ship an lSource without them.
stopifnot(
  "Raw_AE lacks aeout/aereldrv/aesdth: install gsm.mapping and gsm.datasim from dev" =
    all(c("aeout", "aereldrv", "aesdth") %in% names(lSource$Raw_AE)),
  "Raw_AE has no fatal AE linked to a Raw_Death participant" =
    any(
      lSource$Raw_AE$aeout %in% "Fatal" &
        lSource$Raw_AE$subjid %in% lSource$Raw_Death$subjid
    )
)

usethis::use_data(lSource, overwrite = TRUE)

# write CSVs
# Sort reporting data on explicit keys (see sort_reporting.R) so reruns don't
# produce row-order-only diffs in data-raw/ or data/.
source("data-raw/sort_reporting.R")
write_sorted_csv <- function(x, name) {
  write.csv(
    sort_reporting(x, name),
    file = file.path("data-raw", paste0(name, ".csv")),
    row.names = FALSE
  )
}

csv_outputs <- list(
  # analysis data
  analyticsSummary = analyzed[[3]]$Analysis_kri0001$Analysis_Summary,
  analyticsInput = analyzed[[3]]$Analysis_kri0001$Analysis_Input,
  analyticsSummary_country = analyzed[[3]]$Analysis_cou0001$Analysis_Summary,
  analyticsInput_country = analyzed[[3]]$Analysis_cou0001$Analysis_Input,
  # reporting data
  reportingGroups = lReporting_site$Reporting_Groups,
  reportingBounds = lReporting_site$Reporting_Bounds,
  reportingMetrics = lReporting_site$Reporting_Metrics,
  reportingResults = lReporting_site$Reporting_Results,
  reportingGroups_country = lReporting_country$Reporting_Groups,
  reportingBounds_country = lReporting_country$Reporting_Bounds,
  reportingMetrics_country = lReporting_country$Reporting_Metrics,
  reportingResults_country = lReporting_country$Reporting_Results,
  reportingGroups_study = lReporting_study$Reporting_Groups,
  reportingBounds_study = lReporting_study$Reporting_Bounds,
  reportingMetrics_study = lReporting_study$Reporting_Metrics,
  reportingResults_study = lReporting_study$Reporting_Results
)
for (name in names(csv_outputs)) {
  write_sorted_csv(csv_outputs[[name]], name)
}

# Rebuild the bundled data/*.rda objects from the CSVs just written. Without
# this, data/ (and the row counts in the generated Rd files) silently drift out
# of sync with data-raw/.
source("data-raw/sampleData.R")
