#' analyticsInput Dataset
#'
#' `r lifecycle::badge("stable")`
#'
#' Downloaded on first use from a gsm.datasim test data release and cached
#' locally. The release is automatically chosen to match the installed gsm
#' packages. To change where or how the data is cached, see
#' [use_testdata_cache_dir()].
#'
#' @format A data frame with about 754 rows and 6 columns:
#' \describe{
#'   \item{SubjectID}{unique subject identifier}
#'   \item{GroupID}{grouping variable}
#'   \item{GroupLevel}{level of grouping variable}
#'   \item{Numerator}{number of flags in group}
#'   \item{Denominator}{total subjects in group}
#'   \item{Metric}{calculated rate/metric value}
#' }
#' @inheritSection lSource Release selection
#' @source `analyticsInput.rds` from a `data-*` release of
#'   <https://github.com/Gilead-Public/gsm.datasim/releases>.
#' @name analyticsInput
#' @docType data
#' @usage analyticsInput
#' @keywords datasets
NULL

#' analyticsSummary Dataset
#'
#' `r lifecycle::badge("stable")`
#'
#' Downloaded on first use from a gsm.datasim test data release and cached
#' locally. The release is automatically chosen to match the installed gsm
#' packages. To change where or how the data is cached, see
#' [use_testdata_cache_dir()].
#'
#' @format A data frame with about 141 rows and 7 columns:
#' \describe{
#'   \item{GroupID}{grouping variable}
#'   \item{GroupLevel}{level of grouping variable}
#'   \item{Numerator}{number of flags in group}
#'   \item{Denominator}{total subjects in group}
#'   \item{Metric}{calculated rate/metric value}
#'   \item{Score}{statistical score}
#'   \item{Flag}{ordinal flag to be applied}
#' }
#' @inheritSection lSource Release selection
#' @source `analyticsSummary.rds` from a `data-*` release of
#'   <https://github.com/Gilead-Public/gsm.datasim/releases>.
#' @name analyticsSummary
#' @docType data
#' @usage analyticsSummary
#' @keywords datasets
NULL

#' reportingGroups Dataset
#'
#' `r lifecycle::badge("stable")`
#'
#' Downloaded on first use from a gsm.datasim test data release and cached
#' locally. The release is automatically chosen to match the installed gsm
#' packages. To change where or how the data is cached, see
#' [use_testdata_cache_dir()].
#'
#' @format A data frame with about 1655 rows and 4 columns:
#' \describe{
#'   \item{GroupID}{grouping variable}
#'   \item{GroupLevel}{level of grouping variable}
#'   \item{Param}{Parameter of interest for the group}
#'   \item{Value}{Value of specified Param}
#' }
#' @inheritSection lSource Release selection
#' @source `reportingGroups.rds` from a `data-*` release of
#'   <https://github.com/Gilead-Public/gsm.datasim/releases>.
#' @name reportingGroups
#' @docType data
#' @usage reportingGroups
#' @keywords datasets
NULL

#' reportingMetrics Dataset
#'
#' `r lifecycle::badge("stable")`
#'
#' Downloaded on first use from a gsm.datasim test data release and cached
#' locally. The release is automatically chosen to match the installed gsm
#' packages. To change where or how the data is cached, see
#' [use_testdata_cache_dir()].
#'
#' @format A data frame with about 24 rows and 27 columns:
#' \describe{
#'   \item{MetricID}{unique metric identifier}
#'   \item{GroupLevel}{level of grouping variable}
#'   \item{Abbreviation}{abbreviation for the metric}
#'   \item{Metric}{name of the metric}
#'   \item{Numerator}{data source for the numerator}
#'   \item{Denominator}{data source for the denominator}
#'   \item{Model}{model used to calculate metric}
#'   \item{Score}{type of score reported}
#'   \item{Type}{statistical outcome type}
#'   \item{Threshold}{thresholds to be used for bounds and flags}
#'   \item{RiskScoreWeight}{weight assigned to the risk score}
#'   \item{AccrualThreshold}{minimum numerator required to return a score and calculate a flag}
#'   \item{AccrualMetric}{metric used to apply threshold to}
#'   \item{ID}{ID}
#'   \item{Priority}{Priority in workflow}
#'   \item{AnalysisType}{analysis type}
#'   \item{Flag}{thresholds to be used for vFlags argument}
#'   \item{ScoreCol}{Column used for `Analyze_Identity()`}
#'   \item{nNumDeviations}{Number of standard deviations to flag QTL}
#'   \item{nPropRate}{Proposed threshold}
#'   \item{Active}{logical flag indicating whether the metric is active}
#'   \item{GenerateRiskSignal}{logical flag indicating whether to generate a risk signal}
#'   \item{WindowDays}{number of days in the metric's observation window}
#'   \item{ValueCol}{column of repeated measurements evaluated by repeat-measure metrics}
#'   \item{WindowLength}{number of consecutive measurements in each repeat-measure window}
#'   \item{NumeratorCol}{column used as the numerator by repeat-measure metrics}
#'   \item{DenominatorCol}{column used as the denominator by repeat-measure metrics}
#' }
#' @inheritSection lSource Release selection
#' @source `reportingMetrics.rds` from a `data-*` release of
#'   <https://github.com/Gilead-Public/gsm.datasim/releases>.
#' @name reportingMetrics
#' @docType data
#' @usage reportingMetrics
#' @keywords datasets
NULL

#' reportingBounds Dataset
#'
#' `r lifecycle::badge("stable")`
#'
#' Downloaded on first use from a gsm.datasim test data release and cached
#' locally. The release is automatically chosen to match the installed gsm
#' packages. To change where or how the data is cached, see
#' [use_testdata_cache_dir()].
#'
#' @format A data frame with about 33804 rows and 8 columns:
#' \describe{
#'   \item{Threshold}{number of standard deviations that the upper and lower bounds are based on}
#'   \item{Denominator}{calculated denominator value}
#'   \item{LogDenominator}{calculated log denominator value}
#'   \item{Numerator}{calculated numerator value}
#'   \item{Metric}{calculated rate/metric value}
#'   \item{MetricID}{unique metric identifier}
#'   \item{StudyID}{unique study identifier}
#'   \item{SnapshotDate}{date of the snapshot}
#' }
#' @inheritSection lSource Release selection
#' @source `reportingBounds.rds` from a `data-*` release of
#'   <https://github.com/Gilead-Public/gsm.datasim/releases>.
#' @name reportingBounds
#' @docType data
#' @usage reportingBounds
#' @keywords datasets
NULL

#' reportingResults Dataset
#'
#' `r lifecycle::badge("stable")`
#'
#' Downloaded on first use from a gsm.datasim test data release and cached
#' locally. The release is automatically chosen to match the installed gsm
#' packages. To change where or how the data is cached, see
#' [use_testdata_cache_dir()].
#'
#' @format A data frame with about 5880 rows and 10 columns:
#' \describe{
#'   \item{GroupID}{grouping variable}
#'   \item{GroupLevel}{level of grouping variable}
#'   \item{Numerator}{number of flags in group}
#'   \item{Denominator}{total subjects in group}
#'   \item{Metric}{calculated rate/metric value}
#'   \item{Score}{statistical score}
#'   \item{Flag}{ordinal flag to be applied}
#'   \item{MetricID}{unique metric identifier}
#'   \item{StudyID}{unique study identifier}
#'   \item{SnapshotDate}{date of the snapshot}
#' }
#' @inheritSection lSource Release selection
#' @source `reportingResults.rds` from a `data-*` release of
#'   <https://github.com/Gilead-Public/gsm.datasim/releases>.
#' @name reportingResults
#' @docType data
#' @usage reportingResults
#' @keywords datasets
NULL

#' reportingActionLog Dataset
#'
#' Deterministic longitudinal ActionLog records aligned with flagged site KRI
#' rows in [reportingResults]. Each extraction is a complete frozen read of
#' signals known at that snapshot. Multiple actions and unactioned signals
#' follow the source-neutral grail Action Log schema; the result key is not
#' unique without extraction, signal, and action identifiers.
#' States vary across site/KRI pairs; earlier flags on currently green findings
#' are closed. Snapshot dates are labelled proxies, not verified decision dates.
#' The reporting history spans 59 days and does not demonstrate 90-day expiry.
#'
#' @format `r df_dim_desc(reportingActionLog)`
#' \describe{
#'   \item{StudyID}{unique study identifier}
#'   \item{SnapshotDate}{date of the KRI snapshot}
#'   \item{GroupLevel}{level of grouping variable}
#'   \item{GroupID}{grouping variable}
#'   \item{MetricID}{unique metric identifier}
#'   \item{State}{ActionLog state}
#'   \item{ExtractionDate}{date the synthetic ActionLog was extracted}
#'   \item{RiskSignalID}{synthetic risk signal identifier}
#'   \item{RiskSignalURL}{synthetic risk signal URL}
#'   \item{ActionID,ActionURL}{character action identifier and URL, missing for unactioned signals}
#'   \item{ActionState,RiskSignalState}{independent action and risk-signal states}
#'   \item{ActionCreatedDate,ActionResolvedDate}{action lifecycle dates}
#'   \item{ActionCriticality}{logical criticality; missing when unassessed}
#'   \item{MetricType}{risk-signal metric type}
#'   \item{RiskSignalDuplicateFlag}{whether the signal duplicates a scoring key}
#'   \item{RelevantSnapshotDate}{relevant snapshot across the signal history}
#'   \item{RelevantSnapshotFlag}{whether this row is the relevant snapshot}
#'   \item{RiskSignalAge}{age of the signal in days}
#'   \item{AssignedTo,SignalDescription,RecommendedAction,ActionTaken,CTMSID,
#'   CreatedDate,ResolvedDate,FunctionalArea,GroupLabel,MetricLabel,
#'   MetricAbbreviation,Country}{ActionLog display and action metadata}
#' }
#' @source Generated through `gsm.datasim::simulate_action_log_reviews()` by
#'   `data-raw/generate_action_log_fixture.R`.
"reportingActionLog"

#' Synthetic ActionLog quarantine audit
#'
#' A deliberately missing KRI identifier at a known site demonstrates scoped,
#' conservative snapshot scoring. This signal is excluded from [reportingActionLog].
#' The audit belongs to its latest frozen extraction.
#' @format A data frame with StudyID, SnapshotDate, GroupLevel, GroupID,
#'   missing MetricID, RiskSignalID and ExclusionReason columns.
#' @source Generated by `data-raw/generate_action_log_fixture.R` using gsm.datasim.
"reportingActionLogExcludedSignals"

#' reportingGroups_country Dataset
#'
#' `r lifecycle::badge("stable")`
#'
#' Downloaded on first use from a gsm.datasim test data release and cached
#' locally. The release is automatically chosen to match the installed gsm
#' packages. To change where or how the data is cached, see
#' [use_testdata_cache_dir()].
#'
#' @format A data frame with about 29 rows and 4 columns:
#' \describe{
#'   \item{GroupID}{grouping variable}
#'   \item{GroupLevel}{level of grouping variable}
#'   \item{Param}{Parameter of interest for the group}
#'   \item{Value}{Value of specified Param}
#' }
#' @inheritSection lSource Release selection
#' @source `reportingGroups_country.rds` from a `data-*` release of
#'   <https://github.com/Gilead-Public/gsm.datasim/releases>.
#' @name reportingGroups_country
#' @docType data
#' @usage reportingGroups_country
#' @keywords datasets
NULL

#' reportingMetrics_country Dataset
#'
#' `r lifecycle::badge("stable")`
#'
#' Downloaded on first use from a gsm.datasim test data release and cached
#' locally. The release is automatically chosen to match the installed gsm
#' packages. To change where or how the data is cached, see
#' [use_testdata_cache_dir()].
#'
#' @format A data frame with about 23 rows and 27 columns:
#' \describe{
#'   \item{MetricID}{unique metric identifier}
#'   \item{GroupLevel}{level of grouping variable}
#'   \item{Abbreviation}{abbreviation for the metric}
#'   \item{Metric}{name of the metric}
#'   \item{Numerator}{data source for the numerator}
#'   \item{Denominator}{data source for the denominator}
#'   \item{Model}{model used to calculate metric}
#'   \item{Score}{type of score reported}
#'   \item{Type}{statistical outcome type}
#'   \item{Threshold}{thresholds to be used for bounds and flags}
#'   \item{RiskScoreWeight}{weight assigned to the risk score}
#'   \item{AccrualThreshold}{minimum numerator required to return a score and calculate a flag}
#'   \item{AccrualMetric}{metric used to apply threshold to}
#'   \item{ID}{ID}
#'   \item{Priority}{Priority in workflow}
#'   \item{AnalysisType}{analysis type}
#'   \item{Flag}{thresholds to be used for vFlags argument}
#'   \item{ScoreCol}{Column used for `Analyze_Identity()`}
#'   \item{nNumDeviations}{Number of standard deviations to flag QTL}
#'   \item{nPropRate}{Proposed threshold}
#'   \item{Active}{logical flag indicating whether the metric is active}
#'   \item{GenerateRiskSignal}{logical flag indicating whether to generate a risk signal}
#'   \item{WindowDays}{number of days in the metric's observation window}
#'   \item{ValueCol}{column of repeated measurements evaluated by repeat-measure metrics}
#'   \item{WindowLength}{number of consecutive measurements in each repeat-measure window}
#'   \item{NumeratorCol}{column used as the numerator by repeat-measure metrics}
#'   \item{DenominatorCol}{column used as the denominator by repeat-measure metrics}
#' }
#' @inheritSection lSource Release selection
#' @source `reportingMetrics_country.rds` from a `data-*` release of
#'   <https://github.com/Gilead-Public/gsm.datasim/releases>.
#' @name reportingMetrics_country
#' @docType data
#' @usage reportingMetrics_country
#' @keywords datasets
NULL

#' reportingBounds_country Dataset
#'
#' `r lifecycle::badge("stable")`
#'
#' Downloaded on first use from a gsm.datasim test data release and cached
#' locally. The release is automatically chosen to match the installed gsm
#' packages. To change where or how the data is cached, see
#' [use_testdata_cache_dir()].
#'
#' @format A data frame with about 37191 rows and 8 columns:
#' \describe{
#'   \item{Threshold}{number of standard deviations that the upper and lower bounds are based on}
#'   \item{Denominator}{calculated denominator value}
#'   \item{LogDenominator}{calculated log denominator value}
#'   \item{Numerator}{calculated numerator value}
#'   \item{Metric}{calculated rate/metric value}
#'   \item{MetricID}{unique metric identifier}
#'   \item{StudyID}{unique study identifier}
#'   \item{SnapshotDate}{date of the snapshot}
#' }
#' @inheritSection lSource Release selection
#' @source `reportingBounds_country.rds` from a `data-*` release of
#'   <https://github.com/Gilead-Public/gsm.datasim/releases>.
#' @name reportingBounds_country
#' @docType data
#' @usage reportingBounds_country
#' @keywords datasets
NULL

#' reportingResults_country Dataset
#'
#' `r lifecycle::badge("stable")`
#'
#' Downloaded on first use from a gsm.datasim test data release and cached
#' locally. The release is automatically chosen to match the installed gsm
#' packages. To change where or how the data is cached, see
#' [use_testdata_cache_dir()].
#'
#' @format A data frame with about 207 rows and 10 columns:
#' \describe{
#'   \item{GroupID}{grouping variable}
#'   \item{GroupLevel}{level of grouping variable}
#'   \item{Numerator}{number of flags in group}
#'   \item{Denominator}{total subjects in group}
#'   \item{Metric}{calculated rate/metric value}
#'   \item{Score}{statistical score}
#'   \item{Flag}{ordinal flag to be applied}
#'   \item{MetricID}{unique metric identifier}
#'   \item{StudyID}{unique study identifier}
#'   \item{SnapshotDate}{date of the snapshot}
#' }
#' @inheritSection lSource Release selection
#' @source `reportingResults_country.rds` from a `data-*` release of
#'   <https://github.com/Gilead-Public/gsm.datasim/releases>.
#' @name reportingResults_country
#' @docType data
#' @usage reportingResults_country
#' @keywords datasets
NULL

#' reportingGroups_study Dataset
#'
#' `r lifecycle::badge("stable")`
#'
#' Downloaded on first use from a gsm.datasim test data release and cached
#' locally. The release is automatically chosen to match the installed gsm
#' packages. To change where or how the data is cached, see
#' [use_testdata_cache_dir()].
#'
#' @format A data frame with about 23 rows and 4 columns:
#' \describe{
#'   \item{GroupID}{grouping variable}
#'   \item{GroupLevel}{level of grouping variable}
#'   \item{Param}{Parameter of interest for the group}
#'   \item{Value}{Value of specified Param}
#' }
#' @inheritSection lSource Release selection
#' @source `reportingGroups_study.rds` from a `data-*` release of
#'   <https://github.com/Gilead-Public/gsm.datasim/releases>.
#' @name reportingGroups_study
#' @docType data
#' @usage reportingGroups_study
#' @keywords datasets
NULL

#' reportingMetrics_study Dataset
#'
#' `r lifecycle::badge("stable")`
#'
#' Downloaded on first use from a gsm.datasim test data release and cached
#' locally. The release is automatically chosen to match the installed gsm
#' packages. To change where or how the data is cached, see
#' [use_testdata_cache_dir()].
#'
#' @format A data frame with about 2 rows and 27 columns:
#' \describe{
#'   \item{MetricID}{unique metric identifier}
#'   \item{GroupLevel}{level of grouping variable}
#'   \item{Abbreviation}{abbreviation for the metric}
#'   \item{Metric}{name of the metric}
#'   \item{Numerator}{data source for the numerator}
#'   \item{Denominator}{data source for the denominator}
#'   \item{Model}{model used to calculate metric}
#'   \item{Score}{type of score reported}
#'   \item{Type}{statistical outcome type}
#'   \item{Threshold}{thresholds to be used for bounds and flags}
#'   \item{RiskScoreWeight}{weight assigned to the risk score}
#'   \item{AccrualThreshold}{minimum numerator required to return a score and calculate a flag}
#'   \item{AccrualMetric}{metric used to apply threshold to}
#'   \item{ID}{ID}
#'   \item{Priority}{Priority in workflow}
#'   \item{AnalysisType}{analysis type}
#'   \item{Flag}{thresholds to be used for vFlags argument}
#'   \item{ScoreCol}{Column used for `Analyze_Identity()`}
#'   \item{nNumDeviations}{Number of standard deviations to flag QTL}
#'   \item{nPropRate}{Proposed threshold}
#'   \item{Active}{logical flag indicating whether the metric is active}
#'   \item{GenerateRiskSignal}{logical flag indicating whether to generate a risk signal}
#'   \item{WindowDays}{number of days in the metric's observation window}
#'   \item{ValueCol}{column of repeated measurements evaluated by repeat-measure metrics}
#'   \item{WindowLength}{number of consecutive measurements in each repeat-measure window}
#'   \item{NumeratorCol}{column used as the numerator by repeat-measure metrics}
#'   \item{DenominatorCol}{column used as the denominator by repeat-measure metrics}
#' }
#' @inheritSection lSource Release selection
#' @source `reportingMetrics_study.rds` from a `data-*` release of
#'   <https://github.com/Gilead-Public/gsm.datasim/releases>.
#' @name reportingMetrics_study
#' @docType data
#' @usage reportingMetrics_study
#' @keywords datasets
NULL

#' reportingBounds_study Dataset
#'
#' `r lifecycle::badge("stable")`
#'
#' Downloaded on first use from a gsm.datasim test data release and cached
#' locally. The release is automatically chosen to match the installed gsm
#' packages. To change where or how the data is cached, see
#' [use_testdata_cache_dir()].
#'
#' @format A data frame with about 90 rows and 8 columns:
#' \describe{
#'   \item{Threshold}{number of standard deviations that the upper and lower bounds are based on}
#'   \item{Denominator}{calculated denominator value}
#'   \item{LogDenominator}{calculated log denominator value}
#'   \item{Numerator}{calculated numerator value}
#'   \item{Metric}{calculated rate/metric value}
#'   \item{MetricID}{unique metric identifier}
#'   \item{StudyID}{unique study identifier}
#'   \item{SnapshotDate}{date of the snapshot}
#' }
#' @inheritSection lSource Release selection
#' @source `reportingBounds_study.rds` from a `data-*` release of
#'   <https://github.com/Gilead-Public/gsm.datasim/releases>.
#' @name reportingBounds_study
#' @docType data
#' @usage reportingBounds_study
#' @keywords datasets
NULL

#' reportingResults_study Dataset
#'
#' `r lifecycle::badge("stable")`
#'
#' Downloaded on first use from a gsm.datasim test data release and cached
#' locally. The release is automatically chosen to match the installed gsm
#' packages. To change where or how the data is cached, see
#' [use_testdata_cache_dir()].
#'
#' @format A data frame with about 6 rows and 10 columns:
#' \describe{
#'   \item{GroupID}{grouping variable}
#'   \item{GroupLevel}{level of grouping variable}
#'   \item{Numerator}{number of flags in group}
#'   \item{Denominator}{total subjects in group}
#'   \item{Metric}{calculated rate/metric value}
#'   \item{Score}{statistical score}
#'   \item{Flag}{ordinal flag to be applied}
#'   \item{MetricID}{unique metric identifier}
#'   \item{StudyID}{unique study identifier}
#'   \item{SnapshotDate}{date of the snapshot}
#' }
#' @inheritSection lSource Release selection
#' @source `reportingResults_study.rds` from a `data-*` release of
#'   <https://github.com/Gilead-Public/gsm.datasim/releases>.
#' @name reportingResults_study
#' @docType data
#' @usage reportingResults_study
#' @keywords datasets
NULL

#' lSource Dataset
#'
#' `r lifecycle::badge("stable")`
#'
#' Downloaded on first use from a gsm.datasim test data release and cached
#' locally. The release is automatically chosen to match the installed gsm
#' packages. To change where or how the data is cached, see
#' [use_testdata_cache_dir()].
#'
#' @format A named list of 19 data frames, one per raw source
#'   domain, representing a single study snapshot:
#' \describe{
#'   \item{"Raw_AE"}{AE Source dataset}
#'   \item{"Raw_DATACHG"}{DATACHG Source dataset}
#'   \item{"Raw_DATAENT"}{DATAENT Source dataset}
#'   \item{"Raw_Death"}{Death Source dataset}
#'   \item{"Raw_ENROLL"}{Enroll Source dataset}
#'   \item{"Raw_IE"}{IE Source dataset}
#'   \item{"Raw_LB"}{Lab Source dataset}
#'   \item{"Raw_OverallResponse"}{Overall Response Source dataset}
#'   \item{"Raw_PD"}{Protocol Deviation Source dataset}
#'   \item{"Raw_PK"}{PK Source dataset}
#'   \item{"Raw_QUERY"}{Query Source dataset}
#'   \item{"Raw_Randomization"}{Randomization Source dataset}
#'   \item{"Raw_SDRGCOMP"}{SDRGCOMP Source dataset}
#'   \item{"Raw_SITE"}{SITE Source dataset}
#'   \item{"Raw_STUDY"}{Study Source dataset}
#'   \item{"Raw_STUDCOMP"}{STUDCOMP Source dataset}
#'   \item{"Raw_SUBJ"}{SUBJ Source dataset}
#'   \item{"Raw_VISIT"}{Visit Source dataset}
#'   \item{"Raw_VS"}{Vital Signs Source dataset}
#'   }
#' @section Release selection:
#' The data comes from, in order of priority:
#' * [use_testdata_snapshot()]: a local snapshot folder. Nothing is downloaded
#'   or cached.
#' * [use_testdata_tag()]: an exact `data-*` release tag.
#' * Otherwise, the release built with the gsm packages you have installed,
#'   looked up in gsm.datasim's test data index:
#'   1. If gsm.datasim built the data with exactly your installed versions,
#'      that data is used.
#'   2. Otherwise, each installed package narrows the candidates: by its
#'      GitHub commit (`RemoteSha`) if that commit was built, else by the
#'      same version, else by the newest built version no higher than yours.
#'      Packages that aren't installed don't narrow anything.
#'   3. Among the remaining candidates, the most recently built is used.
#'
#'   If nothing matches, an error names the package that ruled out every
#'   build. Usually that means updating it (or the other gsm packages) to a
#'   compatible set.
#'
#' Each override can also be set with an environment variable before gsm.core
#' loads; see [use_testdata_snapshot()].
#' @source `lSource.rds` from a `data-*` release of
#'   <https://github.com/Gilead-Public/gsm.datasim/releases>.
#' @name lSource
#' @docType data
#' @usage lSource
#' @keywords datasets
NULL
