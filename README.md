<!-- badges: start -->

[![R-CMD-check](https://github.com/Gilead-BioStats/gsm.core/workflows/R-CMD-check-main/badge.svg)](https://github.com/Gilead-BioStats/gsm.core/actions)

<!-- badges: end -->

# Good Statistical Monitoring `{gsm.core}` R package

The `{gsm.core}` package provides the analytical foundation for a standardized Risk Based Quality Monitoring (RBQM) framework for clinical trials that pairs a flexible data pipeline with robust reports like the one shown below.

<center>![](man/figures/gsm_report_screenshot_1.png)</center>

This README provides a high-level overview of `{gsm.core}`; see the [package website](https://gilead-biostats.github.io/gsm.core/) for additional details.

The `{gsm.core}` package is a successor package to [`{gsm}`](https://github.com/Gilead-BioStats/gsm), which has been deprecated as of March 2025. The contents of `{gsm}` have been split out among 4 packages as follows:

1.  **`{gsm.core}`**: A package containing the analytics functionality and utility functions to run workflows.
2.  [**`{gsm.mapping}`**](https://github.com/Gilead-BioStats/gsm.mapping): A package that provides workflows to apply the necessary data transformation from raw/source datasets to appropriate domains.
3.  [**`{gsm.kri}`**](https://github.com/Gilead-BioStats/gsm.kri): A package that provides workflows to generate metrics and functionality to visualize and report on these metrics.
4.  [**`{gsm.reporting}`**](https://github.com/Gilead-BioStats/gsm.reporting): A package that provides workflows to generate the reporting data model needed to generate reports.

# Background

The `{gsm.core}` package lays the framework to perform risk assessments primarily focused on detecting differences in quality at the site-level. "High quality" is defined as the absence of errors that matter. We interpret this as focusing on detecting potential issues related to critical data or process across the major risk categories of safety, efficacy, disposition, treatment, and general quality, where each category consists of one or more risk assessment(s). Each risk assessment will analyze the data to flag sites with potential issues and provide a visualization to help the user understand the issue. Some relevant references are provided below.

-   Centralized Statistical Monitoring: [1](https://www.ncbi.nlm.nih.gov/pmc/articles/PMC7308734/), [2](https://pubmed.ncbi.nlm.nih.gov/38796099/)
-   EMA/FDA Guidance on Risk Based Management: [1](https://www.fda.gov/media/121479/download), [2](https://www.fda.gov/media/116754/download), [3](https://www.fda.gov/media/157718/download), [4](https://www.ema.europa.eu/en/documents/scientific-guideline/reflection-paper-risk-based-quality-management-clinical-trials_en.pdf)
-   Risk Based Quality Management: [1](https://www.lexjansen.com/phuse-us/2024/ar/PAP_AR04.pdf), [2](http://www.transceleratebiopharmainc.com/wp-content/uploads/2017/09/Risk-Based-Quality-Managment.pdf), [3](https://pubmed.ncbi.nlm.nih.gov/38722529/)
-   Related tools: [1](https://cluepoints.com/)

# Process Overview

The `{gsm.core}` package is the foundation of a data pipeline for RBM using R. The package, along with `{gsm.mapping}`, `{gsm.kri}` and `{gsm.reporting}` provides a framework that allows users to **assess** and **visualize** site-level risk in clinical trial data. The packages currently provide assessments for the following domains:

1.  Adverse Event Reporting Rate
2.  Serious Adverse Event Reporting Rate
3.  Non-important Protocol Deviation Rate
4.  Important Protocol Deviation Rate
5.  Grade 3+ Lab Abnormality Rate
6.  Study Discontinuation Rate
7.  Treatment Discontinuation Rate
8.  Query Rate
9.  Outstanding Query Rate
10. Outstanding Data Entry Rate
11. Data Change Rate
12. Screen Failure Rate

All `{gsm.core}` assessments use a standardized 6 step data pipeline:

1.  **Input_Rate** - Converts `raw` data to `input` data.
2.  **Transform** - Converts `input` data to `transformed` data.
3.  **Analyze** - Converts `transformed` data to `analyzed` data.
4.  **Threshold** - Uses `analyzed` data to create one or more numeric `thresholds`.
5.  **Flag** - Uses `analyzed` data and numeric `thresholds` to create `flagged` data.
6.  **Summarize** - Selects key columns from `flagged` data to create `summary` data.

To learn more about `{gsm.core}`'s data pipeline, visit the [Data Pipeline article](https://gilead-biostats.github.io/gsm.core/articles/DataModel.html).

# Reporting

Detailed RMarkdown/HTML reporting is built into `{gsm.core}`, and provides a detailed overview of all risk assessments for a given trial. For example, an AE risk assessment looks like this:

<center>![](man/figures/gsm_report_screenshot_2.png)</center>

Full reports for a sample trial run with [`{clindata}`](https://github.com/Gilead-BioStats/clindata) are provided below:

-   [Site Report](https://gilead-biostats.github.io/gsm.kri/examples/Example_SiteReport.html)
-   [Country Report](https://gilead-biostats.github.io/gsm.kri/examples/Example_CountryReport.html)

# Getting Started

Interested in using {gsm}? Key resources are provided in response to the FAQs below.

## How do I calculate a metric?

See the "Process Overview" section above and then check out these articles:

-   [Step-by-Step Analysis Workflow Vignette](https://gilead-biostats.github.io/gsm.core/articles/DataAnalysis.html) walks users the step-by-step process for creating metrics (KRIs, QTLs, etc) in {gsm}.
-   [Adverse Event KRI Cookbook Example](https://gilead-biostats.github.io/gsm.kri/dev/examples/Cookbook_AdverseEventKRI.html) provides hands-on examples of how to customize KRI metrics related to Adverse events.

## How do I evaluate a study?

The {gsm} workflow process allows creation of reusable pipelines for study (or even cross-study) data snapshots including data mapping, calculation of multiple metrics and creation of reports. See the articles below for details and examples.

-   [Data Model Vignette](https://gilead-biostats.github.io/gsm.core/articles/DataModel.html) explains the data pipeline used to calculate multiple metrics and generate study-level reports.
-   [Adverse Event Workflow Example](https://gilead-biostats.github.io/gsm.kri/dev/examples/Cookbook_AdverseEventWorkflow.html) demonstrates how to create a configurable workflow using YAML to define the analysis pipeline.
-   [Reporting Workflow Example](https://gilead-biostats.github.io/gsm.kri/dev/examples/Cookbook_AdverseEventWorkflow.html) demonstrates a complete workflow from raw data to KRI reports using standard metrics.

## How do I customize my study?

The {gsm} framework is designed to be highly modular and customizable. The sections above show examples of customized metrics and workflows. It's also straightforward to add entire custom modules that add new mappings, metrics and reports. See the vignette below for details.

-   [gsm Extensions Vignette](https://gilead-biostats.github.io/gsm.core/articles/gsmExtensions.html) describes how to extend {gsm.core} by creating new ‘modules’, including metrics, reports and shiny apps that can be run using the standard gsm pipeline.

## What reports are available for my study?

Here are links to sample reports that are available in the {gsm} family of packages. We're working on adding more all the time and will continue adding examples to this list as they are released.

-   [Site KRI Report](https://gilead-biostats.github.io/gsm.kri/examples/Example_SiteReport.html)
-   [Country KRI Report](https://gilead-biostats.github.io/gsm.kri/examples/Example_CountryReport.html)
-   [Eligibility Report](https://gilead-biostats.github.io/gsm.kri/dev/examples/Example_Eligibility.html)
-   [Cross-Study Site Risk Score Report](https://gilead-biostats.github.io/gsm.kri/dev/examples/Example_CrossStudySRS.html)
-   [QTL Report](https://gilead-biostats.github.io/gsm.qtl/examples/Example_QTL.html)
-   [Good Statistical Monitoring Shiny App](https://rinpharma.shinyapps.io/gsm-app/)

# Quality Control

Since {gsm.core} is designed for use in a [GCP](https://en.wikipedia.org/wiki/Good_clinical_practice) framework, we have conducted extensive quality control as part of our development process. In particular, we rely on several key components to maintain a consistent and rigorous quality‑control process:

-   **Unit Tests** - Unit tests are written for all core functions.
-   **Workflow/Qualification Tests** - Additional unit tests confirm that core workflows behave as expected. Qualification testing ensures that core functions execute as expected on a system-wide scale. Qualification includes executing various functional, performance, and usability testing. Qualification tests are designed to provide developers with a repeatable process that is easy to update and document.
-   **Code Examples** - The Cookbook articles mentioned above provides a series of simple examples, and all functions include examples as part of roxygen2 documentation.
-   **Code Review** - Code review is conducted using GitHub Pull Requests (PRs). The code is reviewed and approved by QC programmer.
-   **Function Documentation** - Detailed documentation for each function is maintained with roxygen2.
-   **Package Checks** - Standard package checks are run using GitHub Actions and must be passing before PRs are merged.
-   **Data Specifications** - Machine-readable data specifications are maintained for all KRIs. Specifications are automatically added to relevant function documentation.
-   **Continuous Integration** - Continuous integration is provided via GitHub Actions. The full list of GitHub Actions utilized can be found in the [GitHub Actions Workflows](https://gilead-biostats.github.io/gsm.utils/index.html#github-actions-workflows) section of the gsm.utils package
-   **Regression Testing** - Extensive QC and testing is done before each release.

# Qualification Workflow

All quality control checks decsribed above come together into one qualification workflow supported by the [`{qcthat}`](https://gilead-biostats.github.io/qcthat/index.html) package. The `{qcthat}` process provides a structured way to ensure that all requirements for an R package (documented as GitHub issues) are properly tested and verified before a package is released. It does so by compiling the results of all qualification and unit tests that have been written for the package and comparing them against full set of documented requirements (associated GitHub issues). This creates a clear map showing which requirements have evidence supporting their completion and which still need attention. The process can be run automatically as part of the release workflow via GitHub Actions, generating a qualification report that that clearly links requirements, tests, and outcomes. The report also includes a detailed summary of the computing environment used to execute both tests and report generation, adding further traceability. Together, these elements provide a consistent and transparent quality‑control framework.

Additional detail, including links to functional documentation and vignettes, is available in the [package website](https://gilead-biostats.github.io/gsm.core/).

Refer to our **Contributor Guidelines** that includes step-by-step processes for code development and releases are provided in `CONTRIBUTING.md` and visible in the sidebar of the website.