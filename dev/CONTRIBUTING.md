# Introduction

This page outlines the development process for `{gsm}` packages. It
summarizes both our project management and development workflows. The
project management workflow focuses on using issues to are capture user
requirements, bugs and technical requirements. The development workflow
explains how to submit code using the GitHub flow paradigm.

# Project Management

The project management workflow focuses on using issues to capture user
requirements, bugs, and technical requirements. We also use the [gsm
Roadmap](https://github.com/orgs/Gilead-BioStats/projects/41) GitHub
Project to track issues and set priorities across repositories.

## Issues

Issues are the primary way to communicate what needs to be done and to
track progress. Several issue templates are provided to help streamline
this process, including:

- Requirements – Use this template to create a User Requirement.
  Requirements are then assigned sub-issues using the issue types below.
- Bug – Bug reports for when something isn’t working
- Feature – User-facing Functionality
- Technical Task – Non-user facing tasks, such as infrastructure updates
  or internal tooling improvements.
- Documentation Task – Improvements or additions to the documentation
  including function docs, readme updates and vignettes.

The issue templates automatically appear when you select `New Issue` to
create a new issue in a given repository, are maintained in
{[gsm.utils](https://github.com/Gilead-BioStats/gsm.utils)} and
automatically updated in all gsm packages whenever updates are made.
Note that suggestions or other input that might not warrant formal
submission of an issue can be filed in the Github `Discussions` tab for
that repository, which can help facilitate discourse of specific
use-cases or requests.

------------------------------------------------------------------------

## Road Map

The [gsm Roadmap](https://github.com/orgs/Gilead-BioStats/projects/41)
GitHub Project is used to track issues and set priorities across
projects. The gsm team generally batches work into quarterly releases,
although package releases can happen more frequently. Key cross-repo
views in the project include:

- Roadmap – A list of issues split out by quarter. Generally speaking,
  related functionality should be grouped into a Requirement. Key
  columns include:
  - Status – Issue status (e.g. To Do, In Progress, Done).
  - Repository/Milestone
  - Roadmap – Quarter when the requirement is planned for completion.
  - Triage – Has the requirement been approved for development work?
  - Type – Bug, Feature, Task, Documentation.
- Issues – A list of all open non-requirement issues, split by type.
- Releases – All open issues grouped by repo and sorted by milestone.

# Development Workflow

Development is done using R package development best practices ([R
Packages](https://r-pkgs.org/)) and the **GitHub Flow** workflow
([GitHub Flow
Guide](https://docs.github.com/en/get-started/using-github/github-flow)).
The goal is to keep code reliable, traceable, and easy for everyone to
contribute.

------------------------------------------------------------------------

## Branches

We use a simple branching model to keep work organized:

- **`main`** – Stable, production-ready code. Every package release
  comes from here.
- **`dev`** – Working branch that collects all new features, bugfixes,
  and QC tasks before release.
- **`fix-*`** – Short-lived branches for specific issues (feature, bug,
  or QC task). All development starts here.
- **`release-*`** – Temporary branches for regression testing, QC, and
  documentation before merging into `main`.

👉 This structure ensures that unfinished work never goes directly into
production, but can still be tested and reviewed in isolation.

------------------------------------------------------------------------

## Development Workflow

1.  **Open an issue** – every change begins with an issue using the
    right template (`Requirements`, `Bug`, `Feature`,`Technical Task`,
    or `Documentation Task`). This creates a clear record of what’s
    being worked on.
2.  **Create a branch** – branch names link to issues (e.g., `fix-111`
    for issue \#111) so progress is traceable.
3.  **Develop & document** – write clean, consistent code, add roxygen2
    documentation, and create/update
    [testthat](https://testthat.r-lib.org/) unit tests.
4.  **Open a Pull Request** – submit your branch to `dev`, assign
    yourself, request a reviewer, and link the issue. CI checks will run
    automatically.
5.  **Merge & clean up** – once approved and passing checks, merge into
    `dev` and delete the `fix-*` branch.

👉 Following this flow ensures that every contribution is tracked,
tested, and reviewed before becoming part of the development branch.

------------------------------------------------------------------------

## Pull Requests

Pull Requests are where code review happens. To keep them smooth:

- Follow the [tidyverse style guide](https://style.tidyverse.org/). See
  the Code Style section below for details on styling code per GSM
  standards.
- All functions must have **roxygen2 docs** (`@param`, `@return`,
  examples, etc.).
- All changes must include **unit tests** showing expected behavior.
- If Qualification double-programming tests were required per the
  content of the issue(s) tied to the PR, these tests must exist and be
  passing.
- Always **link PRs to their issues** using [closing
  keywords](https://docs.github.com/en/issues/tracking-your-work-with-issues/linking-a-pull-request-to-an-issue-using-a-keyword).
- PRs must pass all **CI checks** (tests, style, docs, coverage) before
  merge.
- Default target branch is `dev`; only **release** PRs target `main`.

👉 A well-prepared PR makes reviewing faster and ensures that releases
are low-risk.

------------------------------------------------------------------------

## Release Workflow

Releases move code from development into production. The goal is to
ensure **reliability, traceability, and reproducibility**:

1.  **Create a `release-x.y.z` branch** from `dev` (using [semantic
    versioning](https://semver.org/)).
2.  **Prepare the release** – update version, NEWS, documentation,
    qualification files, and run checks
    ([`devtools::check()`](https://devtools.r-lib.org/reference/check.html),
    spell check,
    [`pkgdown::build_site()`](https://pkgdown.r-lib.org/reference/build_site.html)).
3.  **Open a release PR** into `main` using the release template. Assign
    yourself and request QC review.
4.  **Link PR to relevant parent issue** in the [gsm Roadmap project
    board](https://github.com/orgs/Gilead-BioStats/projects/41/).
5.  **QC reviewers** complete checklists and may request fixes. Any
    fixes are made in `fix-*` branches and merged back into the release
    branch.
6.  **Complete the release** – once approved, follow the following
    steps:
    - Merge PR into `main`
    - Create a GitHub Release
    - Attach QC reports
    - Create a PR that syncs `main` back into `dev`
    - Ensure related Issues are Closed

👉 This process makes sure that every release is tested, documented, and
signed off before it goes live.

------------------------------------------------------------------------

## Code Style

We follow the [tidyverse style guide](https://style.tidyverse.org/) with
minor tweaks. Before each release, code is standardized with `styler` so
formatting is consistent across the whole repo.

``` r
double_indent_style <- styler::tidyverse_style()
double_indent_style$indention$unindent_fun_dec <- NULL
double_indent_style$indention$update_indention_ref_fun_dec <- NULL
double_indent_style$line_break$remove_line_breaks_in_fun_dec <- NULL
styler::style_dir("R", transformers = double_indent_style)
styler::style_dir("tests", recursive = TRUE, transformers = double_indent_style)
```

------------------------------------------------------------------------

## Continuous Integration

GitHub Actions run automatically on Pull Requests and other repository
events to ensure code quality and provide automated workflows. The
following workflows are configured:

### Core Testing and Quality Assurance

- **R CMD Check (Dev)**
  [`R-CMD-check-dev.yaml`](https://gilead-biostats.github.io/gsm.core/dev/.github/workflows/R-CMD-check-dev.yaml)
  – Runs for PRs to `dev` branch on Ubuntu (latest and R 4.1.3) to catch
  basic package issues.
- **R CMD Check (Main)**
  [`R-CMD-check.yaml`](https://gilead-biostats.github.io/gsm.core/dev/.github/workflows/R-CMD-check.yaml)
  – Comprehensive testing for PRs to `main` branch across multiple
  platforms:
  - **Linux**: Ubuntu (latest R and 4.1.3)
  - **macOS**: macOS-latest (release R)
  - **Windows**: Windows-latest (release R)
- **Test Coverage**
  [`test-coverage.yaml`](https://gilead-biostats.github.io/gsm.core/dev/.github/workflows/test-coverage.yaml)
  – Analyzes code coverage on pushes to `main`/`dev` and PRs, helping
  maintain high test coverage standards.

### Quality Control and Documentation

- **qcthat Quality Control**
  [`qcthat.yaml`](https://gilead-biostats.github.io/gsm.core/dev/.github/workflows/qcthat.yaml)
  – Comprehensive quality control workflow that:
  - Manages User Acceptance Testing (UAT) processes
  - Generates Issue-Test Matrix for tracking test coverage against
    issues
  - Creates and attaches qualification reports to PRs and releases
  - Updates UAT status for closed issues
  - Enforces test failure policies
- **Pkgdown with Examples**
  [`pkgdown-with-examples.yaml`](https://gilead-biostats.github.io/gsm.core/dev/.github/workflows/pkgdown-with-examples.yaml)
  – Builds and deploys package documentation:
  - **Push to `main`**: Deploys the main site to the root of `gh-pages`
    (e.g., `/`)
  - **Push to `dev`**: Deploys the development site to `/dev` on
    `gh-pages`  
  - **Pull Requests**: Deploys preview sites under `/pr/<number>/dev` on
    `gh-pages`
- **Pkgdown Cleanup**
  [`pkgdown-cleanup.yaml`](https://gilead-biostats.github.io/gsm.core/dev/.github/workflows/pkgdown-cleanup.yaml)
  – Automatically removes PR preview directories when PRs are closed.

### Release Management

- **Release** \[`r-releaser.yaml`\] – Handles the release process:
  - Triggered on GitHub release creation or manual dispatch
  - Builds package tarball and attaches to release
  - Ensures proper release artifact management

### Workflow Configuration

Most workflows are generated and maintained through
[`gsm.utils`](https://github.com/Gilead-BioStats/gsm.utils) to ensure
consistency across all GSM packages. The one exception to this is
`qcthat.yaml` which is maintained in the
[`qcthat`](https://github.com/Gilead-BioStats/qcthat) package. Key
features:

- **Automatic triggers**: Workflows run on relevant events (PRs, pushes,
  releases)
- **Multi-platform support**: Testing across Linux, macOS, and Windows
- **Version matrix**: Testing against current and legacy R versions
- **Quality gates**: Enforced testing, coverage, and qualification
  requirements

👉 Contributors don’t need to configure workflows—just push code and the
checks will run automatically. All workflows must pass before PRs can be
merged.

------------------------------------------------------------------------

# Examples

GSM packages should include examples that demonstrate core package
functionality and comply with the following guidelines:

## File Structure and Naming

- Store `{type}_{example}.Rmd` source files in `/inst/examples`
- Output `{type}_{example}.html` files to `/inst/examples/output`
- Output filename must match source filename exactly (including
  capitalization)

## GitHub Actions for Examples

Examples are automatically deployed via GitHub Actions:

- **Push to `main`**: Syncs examples to `/examples` on gh-pages
- **Push to `dev`**: Syncs examples to `/examples/dev` on gh-pages
- **Pull Requests**: Syncs to `/examples/pr-{number}` and adds a comment
  showing new/updated files with timestamps

These workflows are maintained in `gsm.utils` and deployed to all GSM
packages.

------------------------------------------------------------------------

# Appendix 1 – Quick Reference

### Fix Branch Workflow

1.  Open issue with correct template.
2.  Create `fix-*` branch.
3.  Develop code + docs + tests.
4.  Open PR to `dev` (assign self, request review, link issue).
5.  Merge after approval + passing checks.

### Release Branch Workflow

1.  Create `release-x.y.z` branch from `dev`.
2.  Update version, NEWS, docs, qualification files.
3.  Run checks locally + CI in a clean working environment.
4.  Open release PR to `main`.
5.  QC reviewers complete checklist.
6.  Merge, publish GitHub Release, attach QC report.
7.  Sync `main` → `dev` with a PR, close issues, clean up branches.

### QC Checklist

Roxygen2 docs complete (`@export`, `@param`, `@return`, examples).

Unit tests for inputs, outputs, error handling.

Run
[`devtools::check()`](https://devtools.r-lib.org/reference/check.html)
to ensure all checks pass (no errors/warnings/notes).

No sensitive data or hardcoded paths.

Qualification specs + reports updated.

All GitHub Actions checks pass.

------------------------------------------------------------------------

# Appendix 2- Quarterly Release Instructions

This document describes the process for performing a quarterly release
of the `{gsm}` suite of R packages on GitHub. The primary difference
between this release and off-cycle releases is that given the likelihood
of multiple packages being simultaneously updated, the releases must be
done in a specified order to avoid dependency conflicts.

------------------------------------------------------------------------

## Release Workflow for Quarterly Releases

This workflow is similar to the standard release workflow, but with
additional emphasis on ensuring dependencies are up to date and properly
listed in `DESCRIPTION` given this quarter’s release plan.

1.  Create a **release branch** (e.g., `release-x.y.z`) from `main` in
    each package repository.
2.  Update the version number in `DESCRIPTION` to align with the
    Milestones created for this quarter.
3.  Add `NEWS.md` entry with release notes.
4.  Run quality checks, unit tests, and qualification tests to ensure
    all are passing.
5.  Confirm **dependencies are up to date** and properly listed in
    `DESCRIPTION` given this quarter’s release plan and the instructions
    in the Release Order section below.
6.  Create and merge a PR for the release branch.
7.  Tag the release with the semantic version (e.g. `v1.1.0`).
8.  Ensure that qualification report and tarball are appropriately
    attached to each release, as required.
9.  Publish the release on GitHub (use auto-generated release notes +
    NEWS.md).

------------------------------------------------------------------------

## Release Order

Many `{gsm}` packages depend on a small set of foundational packages
(`gsm.core`, `gsm.mapping`, `gsm.kri`, and `gsm.reporting`). These core
packages define shared data structures, helper functions, and reporting
utilities that downstream packages rely on.

Because of this dependency structure, it is **critical** to release
packages in the correct order. If a downstream package is released
before its dependencies are updated, it may:

- Fail to build or check due to mismatched versions.
- Introduce inconsistencies in shared functions or data definitions.
- Break automated workflows (CI/CD, simulations, reporting pipelines).

To prevent these issues, follow the release sequence below:

1.  **gsm.core** – Foundational utilities used by nearly all other
    packages.
2.  **gsm.mapping** – Builds on `gsm.core` to provide study-specific
    mappings.
3.  **gsm.kri** – Depends on `gsm.core` and `gsm.mapping`; provides core
    risk indicator functionality.
4.  **gsm.reporting** – Depends on `gsm.core` and `gsm.kri`; underpins
    all reporting templates.
5.  **gsm.datasim** – Depends on `gsm.core` and `gsm.mapping` for
    generating simulated study data.
6.  **gsm.qtl** – Depends on `gsm.core` and `gsm.kri`.
7.  **gsm.endpoints** – Uses `gsm.mapping` and `gsm.core`. Also extends
    `gsm.kri` and `gsm.reporting` for endpoint-specific analyses.
8.  **grail** – Suggests `gsm.core`, `gsm.mapping`, `gsm.kri` and
    `gsm.reporting`.
9.  **grail.ado** - Depends on `grail` for passing data to ADO.
10. **gsm.rrm** - Suggests `grail` and `gsm.core`.
11. **gsm.template** – Depends on `gsm.core`, `gsm.datasim` and
    `gsm.mapping`.
12. **gsm.app** – Depends on `gsm.core` and `gsm.kri`. Suggests
    `gsm.mapping` and `gsm.reporting`.\`
13. **gsm.ae** – Depends on `gsm.app` and `gsm.mapping`
14. **gsm.qc** – Depends on `gsm.core`, `gsm.mapping`, `gsm.kri` and
    `gsm.reporting`.
15. **gsm.utils** – Optional utilities. No gsm dependencies at this time

**Note:** Not every package requires a release in every cycle. If no
changes have been made (and the version number/NEWS.md do not need
updating), simply skip that package and continue with the next in the
sequence.

By following this order, you ensure that every package is released with
its latest compatible dependencies already available, minimizing risk of
conflicts and downstream errors.

------------------------------------------------------------------------

## Post-Release Steps

- Verify that all release tags are visible on GitHub.
- Add qualification documentation to `r-qualification` repo, as
  required.
- Update the Package Release Tracker with release dates, links to
  releases and qualification information. *Gilead Only*
- Write up a summary of the release updates in an OpenRBQM Discussion.
- Announce release completion to the team on the `gsm` Teams channel
  with link to OpenRBQM Release Discussion.
