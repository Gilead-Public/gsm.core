# Introduction

This page outlines the development process for `{gsm}` packages. It summarizes both our project management and development workflows. The project management workflow focuses on using issues to capture user requirements, bugs, and technical requirements. The development workflow explains how to submit code using the GitHub flow paradigm.

These guidelines are maintained centrally in [`gsm.core`](https://gilead-public.github.io/gsm.core/CONTRIBUTING.html) and apply to every repository in the `{gsm}` universe. Other `gsm` repositories ship a short `CONTRIBUTING.md` stub that links back here.


# Project Management

The project management workflow focuses on using issues to capture user requirements, bugs, and technical requirements. We also use the [gsm Roadmap](https://github.com/orgs/Gilead-BioStats/projects/41) GitHub Project to track issues and set priorities across repositories. 


## Issues

Issues are the primary way to communicate what needs to be done and to track progress. Several issue templates are provided to help streamline this process, including: 

- Requirement – Use this template to create a User Requirement. Requirements are then assigned sub-issues using the issue types below. 
- Bug – Bug reports for when something isn't working
- Feature – User-facing Functionality
- Technical Task – Non-user facing tasks, such as infrastructure updates or internal tooling improvements.
- Documentation Task – Improvements or additions to the documentation including function docs, readme updates and vignettes.

The issue templates automatically appear when you select `New Issue` in a given repository. Blank issues are disabled, so every issue starts from one of the templates above. The templates are maintained in [`gsm.utils`](https://github.com/Gilead-Public/gsm.utils) and are rolled out to all `gsm` packages with `gsm.utils::update_gsm_package()` (see [Repository Tooling](#repository-tooling)).

The `Requirement` template automatically adds the issue to the gsm Roadmap project. Sub-issues (Feature, Bug, Technical Task, Documentation Task) should be linked to their parent Requirement so that work rolls up correctly on the board.

Suggestions or other input that might not warrant formal submission of an issue can be filed in the GitHub `Discussions` tab for that repository, which can help facilitate discourse of specific use-cases or requests.

---

## Road Map

The [gsm Roadmap](https://github.com/orgs/Gilead-BioStats/projects/41) GitHub Project is used to track issues and set priorities across repositories. The gsm team generally batches work into quarterly releases, although package releases can happen more frequently.

The default **Requirements** view lists Requirement issues across all `gsm` repositories, grouped by status. Related functionality should generally be grouped under a single Requirement, with Feature/Bug/Technical/Documentation issues attached as sub-issues. Key fields include:

- **Status** – Where the Requirement sits in the lifecycle:
   - `Backlog` – Captured, but not yet being worked on.
   - `Requirement Gathering` – Scope and acceptance criteria are being defined with stakeholders.
   - `Design` – Technical approach, affected packages, and QC strategy are being worked out.
   - `Development` – Sub-issues are actively being implemented in `fix-*` branches.
   - `Review` – Implementation is complete and undergoing code review and/or QC.
   - `Released` – The work has shipped in a tagged release.
- **Repository / Milestone** – Where the work lives and which release it is targeted for.
- **Roadmap** – Quarter when the Requirement is planned for completion.
- **Type** – Requirement, Bug, Feature, Technical Task, or Documentation Task.

Move a Requirement's status forward as it progresses, and set it to `Released` only after the release containing it has been published. Individual sub-issues are closed by their PRs via [closing keywords](https://docs.github.com/en/issues/tracking-your-work-with-issues/linking-a-pull-request-to-an-issue-using-a-keyword).

# Development Workflow

Development is done using R package development best practices ([R Packages](https://r-pkgs.org/)) and the **GitHub Flow** workflow ([GitHub Flow Guide](https://docs.github.com/en/get-started/using-github/github-flow)).
The goal is to keep code reliable, traceable, and easy for everyone to contribute.

---

## Branches

We use a simple branching model to keep work organized:

* **`main`** – Stable, production-ready code. Every package release comes from here.
* **`dev`** – Working branch that collects all new features, bugfixes, and QC tasks before release.
* **`fix-*`** – Short-lived branches for specific issues (feature, bug, or QC task). All development starts here.
* **`release-*`** – Temporary branches for regression testing, QC, and documentation before merging into `main`.

👉 This structure ensures that unfinished work never goes directly into production, but can still be tested and reviewed in isolation.

---

## Development Workflow

1. **Open an issue** – every change begins with an issue using the right template (`Requirement`, `Bug`, `Feature`, `Technical Task`, or `Documentation Task`). This creates a clear record of what’s being worked on.
2. **Create a branch** – branch names link to issues (e.g., `fix-111` for issue #111) so progress is traceable.
3. **Develop & document** – write clean, consistent code, add roxygen2 documentation, and create/update [testthat](https://testthat.r-lib.org/) unit tests.
4. **Open a Pull Request** – submit your branch to `dev`, assign yourself, request a reviewer, and link the issue. CI checks will run automatically.
5. **Merge & clean up** – once approved and passing checks, merge into `dev` and delete the `fix-*` branch.
6. **Update the board** – move the parent Requirement's Status forward (e.g., `Development` → `Review`) as the work progresses.

👉 Following this flow ensures that every contribution is tracked, tested, and reviewed before becoming part of the development branch.

---

## Pull Requests

Pull Requests are where code review happens. To keep them smooth:

* Follow the [tidyverse style guide](https://style.tidyverse.org/). See the Code Style section below for details on styling code per GSM standards.
* All functions must have **roxygen2 docs** (`@param`, `@return`, examples, etc.).
* All changes must include **unit tests** showing expected behavior.
* If Qualification double-programming tests were required per the content of the issue(s) tied to the PR, these tests must exist and be passing.
* Always **link PRs to their issues** using [closing keywords](https://docs.github.com/en/issues/tracking-your-work-with-issues/linking-a-pull-request-to-an-issue-using-a-keyword).
* PRs must pass all **CI checks** (tests, style, docs, coverage) before merge.
* Default target branch is `dev`; only **release** PRs target `main`.

👉 A well-prepared PR makes reviewing faster and ensures that releases are low-risk.

---

## Release Workflow

Releases move code from development into production. The goal is to ensure **reliability, traceability, and reproducibility**:

1. **Create a `release-x.y.z` branch** from `dev` (using [semantic versioning](https://semver.org/)).
2. **Prepare the release** – update version, NEWS, documentation, qualification files, and run checks (`devtools::check()`, spell check, `pkgdown::build_site()`).
3. **Open a release PR** into `main` using the release template. Assign yourself and request QC review.
4. **Link PR to relevant parent issue** in the [gsm Roadmap project board](https://github.com/orgs/Gilead-BioStats/projects/41/). 
5. **QC reviewers** complete checklists and may request fixes. Any fixes are made in `fix-*` branches and merged back into the release branch.
6. **Complete the release** – once approved, follow the following steps:
    * Merge PR into `main`
    * Create a GitHub Release
    * Attach QC reports
    * Create a PR that syncs `main` back into `dev`
    * Ensure related Issues are Closed
    * Set the Status of related Requirements to `Released` on the gsm Roadmap board

👉 This process makes sure that every release is tested, documented, and signed off before it goes live.

---

## Code Style

We follow the [tidyverse style guide](https://style.tidyverse.org/) with minor tweaks.
Before each release, code is standardized with `styler` so formatting is consistent across the whole repo.

```r
double_indent_style <- styler::tidyverse_style()
double_indent_style$indention$unindent_fun_dec <- NULL
double_indent_style$indention$update_indention_ref_fun_dec <- NULL
double_indent_style$line_break$remove_line_breaks_in_fun_dec <- NULL
styler::style_dir("R", transformers = double_indent_style)
styler::style_dir("tests", recursive = TRUE, transformers = double_indent_style)
```

---

## Repository Tooling

Shared GitHub configuration — issue templates and GitHub Actions workflows — is maintained in [`gsm.utils`](https://github.com/Gilead-Public/gsm.utils) rather than being edited by hand in each repository.

```r
# install.packages("pak")
pak::pak("Gilead-Public/gsm.utils")

# Pull the latest issue templates and workflow templates into this package
gsm.utils::update_gsm_package(strPackageDir = ".")
```

`update_gsm_package()` will:

* Install/update GitHub issue templates (`add_gsm_issue_templates()`) and remove deprecated ones.
* Install/update GitHub Actions workflows from the [`actions-v1` branch](https://github.com/Gilead-Public/gsm.utils/tree/actions-v1/workflow_templates) (`add_actions()`) and remove deprecated ones.

New `gsm` extension packages should be scaffolded with `gsm.utils::init_gsm_package()`, which creates the package skeleton, configures `pkgdown` + GitHub Pages and `testthat`, and then calls `update_gsm_package()`.

👉 If you need to change a workflow or issue template, open the issue and PR against `gsm.utils` — not against the individual package. The one exception is `qcthat.yaml`, which is maintained in [`qcthat`](https://github.com/Gilead-Public/qcthat).

---

## Continuous Integration

GitHub Actions run automatically on Pull Requests and other repository events to ensure code quality and provide automated workflows. The following workflows are configured:

### Core Testing and Quality Assurance

* **R CMD Check (Dev)** [`R-CMD-check-dev.yaml`](.github/workflows/R-CMD-check-dev.yaml) – Runs for PRs to `dev` branch on Ubuntu (latest and R 4.1.3) to catch basic package issues.
* **R CMD Check (Main)** [`R-CMD-check.yaml`](.github/workflows/R-CMD-check.yaml) – Comprehensive testing for PRs to `main` branch across multiple platforms:
  - **Linux**: Ubuntu (latest R and 4.1.3)
  - **macOS**: macOS-latest (release R)
  - **Windows**: Windows-latest (release R)
* **Test Coverage** [`test-coverage.yaml`](.github/workflows/test-coverage.yaml) – Analyzes code coverage on pushes to `main`/`dev` and PRs, helping maintain high test coverage standards.

### Quality Control and Documentation

* **qcthat Quality Control** [`qcthat.yaml`](.github/workflows/qcthat.yaml) – Comprehensive quality control workflow that:
  - Manages User Acceptance Testing (UAT) processes
  - Generates Issue-Test Matrix for tracking test coverage against issues
  - Creates and attaches qualification reports to PRs and releases
  - Updates UAT status for closed issues
  - Enforces test failure policies
* **Pkgdown with Examples** [`pkgdown-with-examples.yaml`](.github/workflows/pkgdown-with-examples.yaml) – Builds and deploys package documentation:
  - **Push to `main`**: Deploys the main site to the root of `gh-pages` (e.g., `/`)
  - **Push to `dev`**: Deploys the development site to `/dev` on `gh-pages`  
  - **Pull Requests**: Deploys preview sites under `/pr/<number>/dev` on `gh-pages`
* **Pkgdown Cleanup** [`pkgdown-cleanup.yaml`](.github/workflows/pkgdown-cleanup.yaml) – Automatically removes PR preview directories when PRs are closed.

### Release Management

* **Release** [`r-releaser.yaml`] – Handles the release process:
  - Triggered on GitHub release creation or manual dispatch
  - Builds package tarball and attaches to release
  - Ensures proper release artifact management

### Workflow Configuration

Most workflows are generated and maintained through [`gsm.utils`](https://github.com/Gilead-Public/gsm.utils) to ensure consistency across all GSM packages. The one exception to this is `qcthat.yaml` which is maintained in the [`qcthat`](https://github.com/Gilead-Public/qcthat) package. Key features:

- **Automatic triggers**: Workflows run on relevant events (PRs, pushes, releases)
- **Multi-platform support**: Testing across Linux, macOS, and Windows
- **Version matrix**: Testing against current and legacy R versions
- **Quality gates**: Enforced testing, coverage, and qualification requirements

👉 Contributors don't need to configure workflows—just push code and the checks will run automatically. All workflows must pass before PRs can be merged.

---

# Examples

GSM packages should include examples that demonstrate core package functionality and comply with the following guidelines:

## File Structure and Naming

* Store `{type}_{example}.Rmd` source files in `/inst/examples`
* Output `{type}_{example}.html` files to `/inst/examples/output`
* Output filename must match source filename exactly (including capitalization)


## GitHub Actions for Examples

Examples are automatically deployed via GitHub Actions:

* **Push to `main`**: Syncs examples to `/examples` on gh-pages
* **Push to `dev`**: Syncs examples to `/examples/dev` on gh-pages
* **Pull Requests**: Syncs to `/examples/pr-{number}` and adds a comment showing new/updated files with timestamps

These workflows are maintained in `gsm.utils` and deployed to all GSM packages.

---

# Workflow Contract for Ecosystem Packages

GSM ecosystem packages (e.g. `gsm.mapping`, `gsm.kri`, `gsm.reporting`, `gsm.endpoints`) ship reusable analysis pipelines as workflow YAMLs. These workflows are collected with workflows from other packages and run by downstream study projects with `workr::RunProject()`.

Because workflows from multiple packages are collected into shared phase folders, every contributing package must follow the same conventions.

## 1. Where workflow YAMLs live

Place workflow YAMLs under **`inst/workflow/`** (singular) in your package:

```
your.package/
└── inst/
    └── workflow/
        ├── 1_mappings/
        ├── 2_metrics/
        └── 3_reporting/
```

* Use the **singular** `inst/workflow/`. This is the canonical location workr looks for.
* Only place actual workflow YAMLs here. Do not store unrelated package data under `inst/workflow/`.

## 2. The numbered-folder (phase) convention

Workflows are grouped into numbered phase directories. Use these names so packages compose predictably:

| Folder | Phase | Contents |
|---|---|---|
| `0_other` | — (not a runnable phase) | Config / spec documents (e.g. study windows, flag specs). **Not** workflow-shaped — no executable `steps`. |
| `1_mappings` | Mappings | `Mapped_*` data-mapping workflows (one per domain). |
| `2_metrics` | Metrics | Metric / analysis workflows (e.g. `kri####`, `cou####`, `end####`). |
| `3_reporting` | Reporting | Reporting workflows that consume metric results. |
| `4_modules` | — (not a runnable phase) | App module specs consumed by `gsm.app`, not executed by `RunProject()`. |

Notes:

* `0_other` and `4_modules` are **not runnable phases** — they hold specs/config and app module definitions, not workflows with executable `steps`.
* Runnable phase folders may include phase-level config files such as `_config.yml` when supported. Keep ordinary spec/config documents in the non-runnable folders.
* Treat this folder set as the ecosystem convention. Coordinate before adding a new top-level numbered folder so snapshot and study workflows agree on phase order.

## 3. Naming rules

* **One workflow per file.** The filename is the workflow's identity within its phase.
* Name files after the workflow's `meta: ID` / output, matching the established pattern for the phase:
  * `1_mappings/` — the domain name, matching the `Mapped_*` output (e.g. `AE.yaml` → `Mapped_AE`, `SUBJ.yaml` → `Mapped_SUBJ`).
  * `2_metrics/` — the metric ID (e.g. `kri0001.yaml`, `end0001.yaml`).
  * `3_reporting/` — the report name (e.g. `Metrics.yaml`, `Results.yaml`).
* Every workflow YAML must declare a `meta:` block with at least `Type`, `ID`, and `Description` (mappings additionally set `Priority`).
* **Fully qualify step functions** with their package namespace (e.g. `gsm.kri::Analyze_NormalApprox`, not bare `Analyze_NormalApprox`). The aggregated bundle is run outside your package's namespace, so unprefixed functions will not resolve at runtime.
* Filenames are case-sensitive in the bundle — keep capitalization consistent with the convention above.

## 4. Collision policy

Workflow files from every package are collected into the same phase folders. Therefore:

* **A filename must be unique across the entire ecosystem within its phase folder.** If two packages each ship `2_metrics/foo.yaml`, they collide.
* Prefer package-distinctive prefixes for metric/report IDs (e.g. `kri####` from `gsm.kri`, `end####` from `gsm.endpoints`) so names stay disjoint as the ecosystem grows.
* Before adding a new workflow, check the other ecosystem packages for an existing file of the same name in the same phase.

## 5. Private-package considerations

If your package is private (e.g. `gsm.endpoints`) and its workflows call functions from private packages at runtime, the workflow is not runnable by a consumer without access to those packages. Document any such access requirement alongside the workflow so consumers can choose an appropriate package set.

---

# Appendix 1 – Quick Reference

### Fix Branch Workflow

1. Open issue with correct template.
2. Create `fix-*` branch.
3. Develop code + docs + tests.
4. Open PR to `dev` (assign self, request review, link issue).
5. Merge after approval + passing checks.
6. Update the parent Requirement's Status on the gsm Roadmap board.

### Release Branch Workflow

1. Create `release-x.y.z` branch from `dev`.
2. Update version, NEWS, docs, qualification files.
3. Run checks locally + CI in a clean working environment.
4. Open release PR to `main`.
5. QC reviewers complete checklist.
6. Merge, publish GitHub Release, attach QC report.
7. Sync `main` → `dev` with a PR, close issues, clean up branches.
8. Set related Requirements to `Released` on the gsm Roadmap board.

### QC Checklist

* [ ] Roxygen2 docs complete (`@export`, `@param`, `@return`, examples).
* [ ] Unit tests for inputs, outputs, error handling.
* [ ] Run `devtools::check()` to ensure all checks pass (no errors/warnings/notes).
* [ ] No sensitive data or hardcoded paths.
* [ ] Qualification specs + reports updated.
* [ ] Issue templates and workflows up to date (`gsm.utils::update_gsm_package()`).
* [ ] All GitHub Actions checks pass.

---

# Appendix 2- Quarterly Release Instructions
  
This document describes the process for performing a quarterly release of the `{gsm}` suite of R packages on GitHub. The primary difference between this release and off-cycle releases is that given the likelihood of multiple packages being simultaneously updated, the releases must be done in a specified order to avoid dependency conflicts.

---
  
## Release Workflow for Quarterly Releases

This workflow is similar to the standard release workflow, but with additional emphasis on ensuring dependencies are up to date and properly listed in `DESCRIPTION` given this quarter's release plan.
  
1. Create a **release branch** (e.g., `release-x.y.z`) from `main` in each package repository.
2. Update the version number in `DESCRIPTION` to align with the Milestones created for this quarter.
3. Add `NEWS.md` entry with release notes.
4. Run quality checks, unit tests, and qualification tests to ensure all are passing.
5. Confirm **dependencies are up to date** and properly listed in `DESCRIPTION` given this quarter's release plan and the instructions in the Release Order section below.
6. Run `gsm.utils::update_gsm_package()` so issue templates and workflows match the current standards.
7. Create and merge a PR for the release branch.
8. Tag the release with the semantic version (e.g. `v1.1.0`).
9. Ensure that qualification report and tarball are appropriately attached to each release, as required.
10. Publish the release on GitHub (use auto-generated release notes + NEWS.md).

---

## Release Order

Most `{gsm}` packages build on a small set of foundational packages (`workr`, `gsm.core`, `gsm.vizr`, `gsm.mapping`, `gsm.reporting`, and `gsm.kri`). These define the workflow engine, shared data structures, helper functions, visualizations, and reporting utilities that downstream packages rely on.

Because of this dependency structure, it is **critical** to release packages in the correct order. If a downstream package is released before its dependencies are updated, it may:

* Fail to build or check due to mismatched versions.
* Introduce inconsistencies in shared functions or data definitions.
* Break automated workflows (CI/CD, simulations, reporting pipelines).

To prevent these issues, follow the release sequence below. **Hard** dependencies are `Depends`/`Imports`; **soft** dependencies are `Suggests` (needed for vignettes, tests, and qualification, so they still influence ordering).

### Tier 1 – Foundation (no `gsm` dependencies)

1. **workr** – Workflow execution engine (`RunWorkflows()`, `RunWorkflow()`, `RunStep()`). Imported by `gsm.core`; no `gsm` dependencies.
2. **qcthat** – QC framework for R packages used in clinical trials; also supplies `qcthat.yaml`. Suggested by `gsm.core`, `gsm.kri`, `gsm.qtl`, and `grail`; no `gsm` dependencies.
3. **gsm.utils** – Developer tooling (issue templates, GitHub Actions, `pkgdown` helpers). No `gsm` dependencies. Release first in a cycle where shared templates changed, so downstream repos can sync.

### Tier 2 – Core

4. **gsm.core** – Analytics framework and workflow utilities. Imports `workr`.
5. **gsm.vizr** – Shared visualization layer. Imports `gsm.core`.
6. **gsm.mapping** – Data mapping framework. Imports `gsm.core`, `workr`.
7. **gsm.reporting** – Reporting data model. Imports `gsm.core`; suggests `gsm.kri`, `gsm.mapping`.
8. **gsm.qtl** – QTL functions, workflows, and report templates. Imports `gsm.core`, `gsm.vizr`.
9. **gsm.kri** – KRI metrics and visualizations. Imports `gsm.core`, `gsm.vizr`, `workr`; suggests `gsm.mapping`, `gsm.reporting`, `gsm.qtl`.

### Tier 3 – Extensions and applications

10. **gsm.datasim** – Synthetic study data. Imports `workr`; suggests `gsm.core`, `gsm.kri`, `gsm.mapping`, `gsm.reporting`.
11. **gsm.endpoints** – Endpoint monitoring module. Imports `gsm.vizr`; suggests `gsm.core`, `gsm.kri`, `gsm.mapping`, `gsm.reporting`.
12. **grail** – Risk signal structuring and actioning. Suggests `gsm.core`, `gsm.endpoints`, `gsm.kri`, `gsm.mapping`, `gsm.qtl`, `gsm.reporting`.
13. **grail.ado** – Azure DevOps integration. Imports `grail`.
14. **gsm.rrm** – Risk Review Meeting materials. Suggests `grail`.
15. **gsm.template** – Study file structure generator. Imports `gsm.datasim`, `gsm.mapping`, `workr`.
16. **gsm.app** – Shiny application. Imports `gsm.core`, `gsm.kri`; suggests `gsm.mapping`, `gsm.reporting`.
17. **gsm.ae** – Adverse Events modules for `gsm.app`, maintained in the [`OpenRBQM`](https://github.com/OpenRBQM/gsm.ae) org. Imports `gsm.app (>= 2.5.2)`, `gsm.mapping`.

**Note on soft cycles:** `gsm.kri` suggests `gsm.reporting` and `gsm.qtl`, while `gsm.reporting` suggests `gsm.kri`. These are `Suggests`-only cycles, so they cannot be fully linearized. Release `gsm.reporting` and `gsm.qtl` before `gsm.kri`, then re-run `gsm.reporting`'s checks against the new `gsm.kri` before closing out the cycle.

**Note on version floors:** Several `DESCRIPTION` files pin minimum versions (e.g. `gsm.kri` requires `gsm.core (>= 1.3.1)`, `gsm.template` requires `gsm.datasim (>= 2.0.0)`). Bump these floors in the downstream package whenever you rely on newly added upstream behavior.

**Note on `Remotes`:** Packages are spread across three orgs — public packages under [`Gilead-Public`](https://github.com/Gilead-Public), Gilead-internal packages under `Gilead-BioStats`, and `gsm.ae` under [`OpenRBQM`](https://github.com/OpenRBQM). Confirm each `Remotes:` entry points at the correct org before releasing.

**Note:** Not every package requires a release in every cycle. If no changes have been made (and the version number/NEWS.md do not need updating), simply skip that package and continue with the next in the sequence.

By following this order, you ensure that every package is released with its latest compatible dependencies already available, minimizing risk of conflicts and downstream errors.

---
  
## Post-Release Steps
  
* Verify that all release tags are visible on GitHub.
* Add qualification documentation to `r-qualification` repo, as required.
* Update the Package Release Tracker with release dates, links to releases and qualification information. *Gilead Only*
* Set the Status of all related Requirements to `Released` on the [gsm Roadmap](https://github.com/orgs/Gilead-BioStats/projects/41).
* Write up a summary of the release updates in an OpenRBQM Discussion.
* Announce release completion to the team on the `gsm` Teams channel with link to OpenRBQM Release Discussion.

