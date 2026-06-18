# Changelog

## gsm.core v1.2.2 (development version)

- Document the workflow contract for ecosystem packages in
  `CONTRIBUTING.md` (workflow YAML location, numbered-phase convention,
  naming rules, and collision policy), with a pointer from the README
  ([\#145](https://github.com/Gilead-BioStats/gsm.core/issues/145)).

## gsm.core v1.2.1

This patch release updates the GitHub action workflows to align with the
new federated action framework in `gsm.utils`

## gsm.core v1.2.0

This minor release expands the qualification / workflow test suite,
refreshes packaged example datasets, and updates release/CI/docs
scaffolding.

Changes:

- Add qualification helpers + multiple new qualification tests and
  custom YAML workflows under tests/testthat/.
- Refresh packaged data objects (data/\*.rda) and their docs/snapshots
  to match regenerated CSV sources.
- Bump package version to 1.2.0 and update release tooling/docs/CI
  configuration.

## gsm.core v1.1.8

This patch release adds the `db_lock_dt` to `Raw_STUDY` in the `lSource`
dataset, implementing updates from gsm.datasim v1.1.3 and gsm.mapping
v1.1.2

## gsm.core v1.1.7

This patch release adds the IE domain to the `lSource` .rda object used
across example reports and workflows in other `gsm` ecosystem packages,
introducing study-level QTL metrics and associated reporting datasets,
as well as minor documentation updates and standardization of the github
actions used in CI/CD.

## gsm.core v1.1.6

This patch release adds site risk score metric to `reportingResults` and
updates documentation.

## gsm.core v1.1.5

This patch release enhances the `Flag` function to support
`vRiskScoreWeight` which are weights to apply to each flag value. It
also adds new contributor guidelines and standardized issue templates.

## gsm.core v1.1.4

This patch release enhances the `RunQuery` function’s type handling and
schema application capabilities.

- Improved type handling in `RunQuery` to use existing data frame column
  types when not explicitly specified in the schema
- Enhanced error handling for unsupported column types with proper
  logging

## gsm.core v1.1.3

This patch addresses a bug in the `lSource` .rda object found in the
`STUDCOMP` domain, affecting only examples and reports that use it.

## gsm.core v1.1.2

The patch releases a new `lSource` .rda object used across example
reports and workflows in other `gsm` ecosystem packages, as well as
fixes a bug so that missing dates are handled appropriately upon
ingestion.

## gsm.core v1.1.1

This patch release fixes a few CLI messages from RunStep(), adds new
“timestamp” and “logical” `types` to mapping specs, and addresses
erroneous warning messages in the testing suite. It also prepares the
package for CRAN release

## gsm.core v1.1.0

This minor release adds PK analysis functionality and updates package
data to use `{gsm.datasim}`. Specifically: - `lSource` package data has
been updated to include PK data - `analytics` and `reporting` package
data is now generated using `{gsm.datasim}` simulated data as the source
data. - Updates to the
[`Flag()`](https://gilead-biostats.github.io/gsm.core/dev/reference/Flag.md)
and
[`Summarize()`](https://gilead-biostats.github.io/gsm.core/dev/reference/Summarize.md)
functions to make thresholds more flexible. The
[`Flag_Accrual()`](https://gilead-biostats.github.io/gsm.core/dev/reference/Flag_Accrual.md)
helper function now allows thresholds to be based on the Numerator,
Denominator, or Difference between the two.

For more details on the changes and new features, please refer to the
documentation and pull requests linked to this release.

## gsm.core v1.0.0

We are excited to announce the first major release of the `gsm.core`
package, which serves as the backbone of the GSM pipeline. This package
provides the analytics framework for constructing metrics and includes
utility functions to execute workflows.

#### Key Features and Updates:

- **Integration with Other gsm Packages:**  
  The package is designed to seamlessly integrate with other GSM modules
  (e.g., `gsm.mapping`, `gsm.reporting`, `gsm.kri`), ensuring smooth
  data flow and interoperability across the pipeline. It serves as the
  central hub for analytics and workflow execution.

#### Other Updates:

- Bug fixes and minor improvements to the existing utility functions.

For more details on the changes and new features, please refer to the
documentation and pull requests linked to this release.
