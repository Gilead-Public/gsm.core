# AI Assistant Instructions for GSM Packages

**IMPORTANT:** Always read and follow the [CONTRIBUTING.md](CONTRIBUTING.md) guidelines. This file provides GSM-specific context and patterns to supplement those guidelines.

## Quick Links

- **[CONTRIBUTING.md](CONTRIBUTING.md)** - **READ THIS FIRST** - Complete development workflow, branching strategy, release process
- **Example Framework** - See [Examples section below](#examples)
- **Package Structure** - See [Package Structure section below](#package-structure)

## Project Overview

The GSM (Good Statistical Monitoring) suite is a collection of R packages for Risk-Based Quality Management (RBQM) in clinical trials. The packages work together to provide:

- **Data mapping** - Transform raw clinical data into analysis-ready formats
- **Metric calculation** - Compute metrics including Key Risk Indicators (KRIs) and Quality Tolerance Limits (QTLs) for study oversight
- **Reporting** - Generate interactive HTML reports and visualizations
- **Workflows** - YAML-based pipeline definitions for reproducible analyses

## Package Structure

```
gsm.core       # Foundational utilities, workflows, data structures
gsm.mapping    # Study-specific data mappings
gsm.kri        # Key Risk Indicator calculations
gsm.reporting  # Report generation and visualizations
gsm.utils      # Development utilities and tooling
```

**Important:** Always respect dependency order when making changes. See [CONTRIBUTING.md](CONTRIBUTING.md#release-order) for the complete release order and dependency details.

## Workflow Patterns

### YAML Workflows
GSM uses YAML to define analysis pipelines with clear metadata and step sequences:

```yaml
meta:
  Type: Analysis
  ID: kri0001
  Metric: Adverse Event Rate
  Threshold: -2,-1,2,3
  
steps:
  - output: Analysis_Input
    name: Input_Rate
    params:
      dfSubjects: Mapped_SUBJ
      strGroupCol: invid
```

### Data Pipeline
Standard flow: **Raw → Mapped → Metrics → Reporting → Modules**

```r
# Step 1 - Mappings
mappings_wf <- MakeWorkflowList(strPath = "workflow/1_mappings", strPackage = "gsm.mapping")
mapped <- RunWorkflows(mappings_wf, lRaw)

# Step 2 - Metrics
metrics_wf <- MakeWorkflowList(strPath = "workflow/2_metrics", strPackage = "gsm.kri")
analyzed <- RunWorkflows(metrics_wf, mapped)

# Step 3 - Reporting
reporting_wf <- MakeWorkflowList(strPath = "workflow/3_reporting", strPackage = "gsm.reporting")
reporting <- RunWorkflows(reporting_wf, c(mapped, list(lAnalyzed = analyzed)))

# Step 4 - Modules
module_wf <- MakeWorkflowList(strPath = "workflow/4_modules", strPackage = "gsm.kri")
lReports <- RunWorkflows(module_wf, reporting)
```

## Common Patterns

### Widget Functions
Interactive visualizations often need specific data structures:

```r
# Bar charts need summary data
Widget_BarChart(dfResults = analysis$Analysis_Summary, lMetric = labels)

# Scatter plots need analysis results + bounds
dfBounds <- Analyze_NormalApprox_PredictBounds(
  analysis$Analysis_Transformed,
  vThreshold = c(-3,-2,2,3)
)
Widget_ScatterPlot(analysis, lMetric = labels, dfBounds = dfBounds)
```

### Column Name Conventions
- **Subject ID**: `subjid`
- **Site/Investigator**: `invid` (not `siteid`)
- **Study ID**: `studyid`
- **Group columns**: Specified via `strGroupCol` parameter

## Development Workflow Guidelines

See [CONTRIBUTING.md](CONTRIBUTING.md#development-workflow) for the complete workflow. Key points:

- Always start with an issue using the appropriate template
- Create `fix-{issue-number}` branches from `dev`
- All functions require roxygen2 documentation
- All changes require unit tests
- PRs must pass CI checks (R CMD check, tests, style, coverage)
- Follow the [tidyverse style guide](https://style.tidyverse.org/)

## Working on Issues - Step-by-Step Workflow

When asked to "work on issue #X" or similar, follow this workflow:

### 1. Fetch Issue Details
Always use `gh issue` to pull complete issue information:

```bash
# View issue with all comments
cd /path/to/repository
gh issue view {issue-number} --comments

# Example: gh issue view 93 --comments
```

**Important:** Issues often contain critical context in comments. Always fetch the full issue including comments before starting work.

### 2. Understand Requirements
- Read the issue description and all comments carefully
- Check for linked issues or related PRs mentioned
- Identify acceptance criteria and scope
- Note any QC requirements (unit tests, double-programming, etc.)

### 3. Plan Implementation
- Break down the work into logical steps
- Identify files that need to be created or modified
- Check dependencies on other packages or issues
- Verify current branch (should be on `dev` or a `fix-*` branch)

### 4. Execute Work
- Follow patterns established in [CONTRIBUTING.md](CONTRIBUTING.md)
- Write code with proper documentation (roxygen2)
- Create/update unit tests
- Maintain consistency with existing code style

### 5. Verify Changes
- Run relevant tests
- Check for errors with `devtools::check()` when applicable
- Review git status to confirm all intended changes are captured
- Ensure no unintended files are modified
- Ask user if they are ready to commit/push code 

## Common Data Sources

```r
# Simulated study data from gsm.core
dm <- gsm.core::lSource$Raw_SUBJ    # Demographics
ae <- gsm.core::lSource$Raw_AE      # Adverse events

# Pre-calculated reporting data
gsm.core::reportingResults          # KRI results
gsm.core::reportingGroups           # Site/study metadata
gsm.core::reportingMetrics          # Metric definitions
gsm.core::reportingBounds           # Statistical bounds
```

## Need Help?

- Read the [full contributing guide](CONTRIBUTING.md)
- Check existing examples in `/inst/examples`
- Review workflow YAML files in `/workflow` directories
- Ask questions in GitHub Discussions
