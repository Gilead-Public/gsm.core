test_that("gsm.core runtime wrappers warn and forward", {
  wf_mapping <- workr::MakeWorkflowList(strPath = "testdata/mappings")
  workflow <- workr::MakeWorkflowList(strPath = "testdata/metrics")[[1]]
  lRaw <- list(
    Raw_SUBJ = gsm.core::lSource$Raw_SUBJ,
    Raw_AE = gsm.core::lSource$Raw_AE
  )

  mapped <- suppressMessages(workr::RunWorkflows(wf_mapping[1:2], lRaw))
  expected <- suppressMessages(workr::RunWorkflow(workflow, mapped, bReturnResult = FALSE, bKeepInputData = FALSE))

  expect_warning(gsm.core::MakeWorkflowList(strPath = "testdata/mappings"), "deprecated")
  expect_warning(suppressMessages(gsm.core::RunWorkflows(wf_mapping[1:2], lRaw)), "deprecated")
  expect_warning(
    actual <- suppressMessages(gsm.core::RunWorkflow(workflow, mapped, bReturnResult = FALSE, bKeepInputData = FALSE)),
    "deprecated"
  )
  expect_equal(actual, expected)
})

wf_mapping <- workr::MakeWorkflowList(strPath = "testdata/mappings")
workflows <- workr::MakeWorkflowList(strPath = "testdata/metrics")

# Don't run things we don't use.
used_params <- purrr::map(workflows, ~ purrr::map(.x$steps, "params")) %>%
  unlist() %>%
  unique()
wf_mapping$steps <- purrr::keep(
  wf_mapping$steps,
  ~ .x$output %in% used_params
)
# Source Data
lSource <- gsm.core::lSource

# Step 0 - Data Ingestion - standardize tables/columns names
lRaw <- list(
  Raw_SUBJ = lSource$Raw_SUBJ,
  Raw_AE = lSource$Raw_AE,
  Raw_PD = lSource$Raw_PD %>%
    dplyr::rename(subjid = "subjectenrollmentnumber"),
  Raw_LB = lSource$Raw_LB,
  Raw_STUDCOMP = lSource$Raw_STUDCOMP %>%
    dplyr::select("subjid", "compyn"),
  Raw_SDRGCOMP = lSource$Raw_SDRGCOMP,
  Raw_DATACHG = lSource$Raw_DATACHG %>%
    dplyr::rename(subject_nsv = "subjectname"),
  Raw_DATAENT = lSource$Raw_DATAENT %>%
    dplyr::rename(subject_nsv = "subjectname"),
  Raw_QUERY = lSource$Raw_QUERY %>%
    dplyr::rename(subject_nsv = "subjectname"),
  Raw_ENROLL = lSource$Raw_ENROLL,
  Raw_SITE = lSource$Raw_SITE %>%
    dplyr::rename(studyid = "protocol") %>%
    dplyr::rename(invid = "pi_number") %>%
    dplyr::rename(InvestigatorFirstName = "pi_first_name") %>%
    dplyr::rename(InvestigatorLastName = "pi_last_name") %>%
    dplyr::rename(City = "city") %>%
    dplyr::rename(State = "state") %>%
    dplyr::rename(Country = "country") %>%
    dplyr::rename(Status = "site_status"),
  Raw_STUDY = lSource$Raw_STUDY %>%
    dplyr::rename(studyid = "protocol_number") %>%
    dplyr::rename(Status = "status")
)

# Create Mapped Data
lMapped <- quiet_RunWorkflows(lWorkflows = wf_mapping, lData = lRaw)

# Run Metrics
results <- purrr::map(
  workflows,
  ~ quiet_RunWorkflow(lWorkflow = .x, lData = lMapped, bReturnResult = FALSE, bKeepInputData = FALSE)
)

yaml_outputs <- purrr::map(
  purrr::map(workflows, ~ purrr::map_vec(.x$steps, ~ .x$output)),
  ~ .x[!grepl("lCharts", .x)]
)

# The workflow runtime itself is tested in {workr}. This test stays in
# {gsm.core} because it checks that every gsm.core analytics step in the
# metric workflows returns data.
test_that("gsm.core metric workflow steps all produce populated outputs (contains rows of data)", {
  expect_no_error({
    purrr::iwalk(
      yaml_outputs,
      function(this_output_set, this_name) {
        expect_true(
          all(map_int(results[[this_name]]$lData[this_output_set], NROW) > 0)
        )
      }
    )
  })
})
