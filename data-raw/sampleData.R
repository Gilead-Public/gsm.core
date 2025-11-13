reportingGroups <- read.csv("data-raw/reportingGroups.csv")
usethis::use_data(reportingGroups, overwrite = TRUE, compress = "bzip2")
rm(reportingGroups)

analyticsInput <- read.csv("data-raw/analyticsInput.csv", colClasses = c(GroupID = "character"))
usethis::use_data(analyticsInput, overwrite = TRUE, compress = "bzip2")
rm(analyticsInput)

reportingMetrics <- read.csv("data-raw/reportingMetrics.csv")
usethis::use_data(reportingMetrics, overwrite = TRUE, compress = "gzip")
rm(reportingMetrics)

reportingResults <- read.csv("data-raw/reportingResults.csv", colClasses = c(GroupID = "character"))
reportingResults$SnapshotDate <- as.Date(reportingResults$SnapshotDate)
usethis::use_data(reportingResults, overwrite = TRUE, compress = "xz")
rm(reportingResults)

analyticsSummary <- read.csv("data-raw/analyticsSummary.csv", colClasses = c(GroupID = "character"))
usethis::use_data(analyticsSummary, overwrite = TRUE, compress = "gzip")
rm(analyticsSummary)

reportingBounds <- read.csv("data-raw/reportingBounds.csv")
reportingBounds$SnapshotDate <- as.Date(reportingBounds$SnapshotDate)
usethis::use_data(reportingBounds, overwrite = TRUE, compress = "xz")
rm(reportingBounds)

## country data
reportingGroups_country <- read.csv("data-raw/reportingGroups_country.csv")
usethis::use_data(reportingGroups_country, overwrite = TRUE, compress = "gzip")
rm(reportingGroups_country)

reportingBounds_country <- read.csv("data-raw/reportingBounds_country.csv")
reportingBounds_country$SnapshotDate <- as.Date(reportingBounds_country$SnapshotDate)
usethis::use_data(reportingBounds_country, overwrite = TRUE, compress = "xz")
rm(reportingBounds_country)

reportingMetrics_country <- read.csv("data-raw/reportingMetrics_country.csv")
usethis::use_data(reportingMetrics_country, overwrite = TRUE, compress = "gzip")
rm(reportingMetrics_country)

reportingResults_country <- read.csv("data-raw/reportingResults_country.csv")
reportingResults_country$GroupID <- as.character(reportingResults_country$GroupID)
reportingResults_country$SnapshotDate <- as.Date(reportingResults_country$SnapshotDate)
usethis::use_data(reportingResults_country, overwrite = TRUE, compress = "gzip")
rm(reportingResults_country)


## study data
reportingGroups_study <- read.csv("data-raw/reportingGroups_study.csv")
usethis::use_data(reportingGroups_study, overwrite = TRUE, compress = "gzip")
rm(reportingGroups_study)

reportingBounds_study <- read.csv("data-raw/reportingBounds_study.csv")
reportingBounds_study$SnapshotDate <- as.Date(reportingBounds_study$SnapshotDate)
usethis::use_data(reportingBounds_study, overwrite = TRUE, compress = "xz")
rm(reportingBounds_study)

reportingMetrics_study <- read.csv("data-raw/reportingMetrics_study.csv")
usethis::use_data(reportingMetrics_study, overwrite = TRUE, compress = "gzip")
rm(reportingMetrics_study)

reportingResults_study <- read.csv("data-raw/reportingResults_study.csv")
reportingResults_study$GroupID <- as.character(reportingResults_study$GroupID)
reportingResults_study$SnapshotDate <- as.Date(reportingResults_study$SnapshotDate)
usethis::use_data(reportingResults_study, overwrite = TRUE, compress = "gzip")
rm(reportingResults_study)
