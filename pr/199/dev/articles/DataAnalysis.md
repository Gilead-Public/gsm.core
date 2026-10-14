# Step-by-Step Analysis Workflow

## Introduction

This vignette walks users through the mechanics of the functions that
produce all of the Analysis workflow output within the
[gsm.core](https://gilead-public.github.io/gsm.core) package. The suite
of `{gsm}` packages leverages Key Risk Indicators (KRIs) and thresholds
to conduct study-level and site-level Risk Based Monitoring for clinical
trials.

These functions provide data frames, visualizations, and metadata to be
used in reporting and error checking at clinical sites. The image below
illustrates the supporting functions that feed into the yaml workflow
that is specified in each analysis workflow.

``` mermaid

%%{init: {"flowchart": {"nodeSpacing": 20, "rankSpacing": 30}}}%%
flowchart TB
  subgraph workflow ["YAML KRI workflow (e.g. gsm.kri kri0001.yaml)"]
    direction TB
    mapped[("Mapped data<br>(workflow spec inputs)")]
    input["<b>dfInput</b><br>participant-level numerator and denominator"]
    transformed["<b>dfTransformed</b><br>group-level metric"]
    analyzed["<b>dfAnalyzed</b><br>group-level analysis results"]
    flagged["<b>dfFlagged</b><br>analysis results with flags"]
    summary["<b>dfSummary</b><br>standardized results for aggregation"]

    mapped -->|"Input_Rate()"| input
    input -->|"Transform_*()"| transformed
    transformed -->|"Analyze_*()"| analyzed
    analyzed -->|"Flag()"| flagged
    flagged -->|"Summarize()"| summary
  end
```

All of these functions will run automatically and sequentially when a
user calls
[`workr::RunWorkflow()`](https://rdrr.io/pkg/workr/man/RunWorkflow.html)
with a specified yaml file for KRI metrics found in the
`inst/workflow/2_metrics` directory of the
[`{gsm.kri}`](https://github.com/Gilead-Public/gsm.kri) package.

Each of these individual functions can also be run independently outside
of a specified yaml workflow.

For the purposes of this documentation, we will evaluate the input(s)
and output(s) of each individual function for a specific KRI to show the
stepwise progression of how a yaml workflow is set up to handle and
process data.

------------------------------------------------------------------------

### Case Study - Step-by-Step Adverse Event KRI

We will use sample clinical data simulated with the
[`{gsm.datasim}`](https://github.com/Gilead-Public/gsm.datasim) package
to reproduce, step by step, the Adverse Event (AE) KRI (`kri0001` in
`{gsm.kri}`), which uses the normal approximation method.

Additional statistical methods and supporting functions are explored in
[Appendix 1](#appendix-1).

#### 1. Create `dfInput`

Start by creating `dfInput` using sample rawplus data created with
`{gsm.datasim}`. Note that
[`Input_Rate()`](https://gilead-public.github.io/gsm.core/dev/reference/Input_Rate.md)
requires three datasets: a subject-level dataset (`dfSubjects`) that
assigns each subject to a group, a numerator dataset (`dfNumerator`;
here, one record per adverse event), and a denominator dataset
(`dfDenominator`; here, the subject-level dataset containing time on
study). In this example, `dfSubjects` and `dfDenominator` are the same
data frame.

Since
[`Input_Rate()`](https://gilead-public.github.io/gsm.core/dev/reference/Input_Rate.md)
is a generalized function, it is also required that you specify the
relevant column names for the Subject (`strSubjectCol`), Group
(`strGroupCol`) and optionally the Denominator (`strDenominatorCol`) and
Numerator (`strNumeratorCol`) when it is not simply “Denominator” or
“Numerator”, respectively. `strGroupLevel` labels the type of group
(e.g. “Site” or “Country”); if omitted, it defaults to the value of
`strGroupCol`.

Finally, the method for calculating the Numerator and Denominator is
specified in `strNumeratorMethod` and `strDenominatorMethod` as either
“Count” or “Sum”. If the method is “Count”, the function counts the
number of rows per subject in the provided data frame. If the method is
“Sum”, the function sums the values of the specified column
(`strNumeratorCol` or `strDenominatorCol`) per subject.

``` r

dfInput <- Input_Rate(
              dfSubjects = gsm.core::lSource$Raw_SUBJ,
              dfNumerator = gsm.core::lSource$Raw_AE,
              dfDenominator = gsm.core::lSource$Raw_SUBJ,
              strSubjectCol = "subjid",
              strGroupCol = "invid",
              strGroupLevel = "Site",
              strNumeratorMethod = "Count",
              strDenominatorMethod = "Sum",
              strDenominatorCol = "timeonstudy"
)
```

The data frame `dfInput` for an AE assessment will be created by running
[`Input_Rate()`](https://gilead-public.github.io/gsm.core/dev/reference/Input_Rate.md)
and will have one record per subject, with the following columns:

- `SubjectID`: Subject Identifier
- `GroupID`: Group Identifier
- `GroupLevel`: Type of Group specified in `GroupID` (Country, Site)
- `Numerator`: Total Number of Event(s) of Interest (in this example,
  the number of AEs reported; per subject)
- `Denominator`: Total Time on Study (measured in days; per subject)
- `Metric`: Rate of Event Incidence (calculated as
  `Numerator`/`Denominator`; per subject)

------------------------------------------------------------------------

#### 2. Create `dfTransformed`

The data frame `dfTransformed` is derived from `dfInput` using a
`Transform()` function. In our example, the analysis pipeline pulls in
[`Transform_Rate()`](https://gilead-public.github.io/gsm.core/dev/reference/Transform_Rate.md)
since the default metric for AEs is the number of AEs reported over the
course of treatment per site, i.e., a rate.

``` r

dfTransformed <- Transform_Rate(dfInput)
#> Warning: 3 values of [ GroupID ] with a [ Denominator ] value of 0
#> removed.
```

The resulting `dfTransformed` data frame will contain site-level
transformed data, including KRI calculation. Using our example AE data,
`dfTransformed` contains the following columns:

- `GroupID`: Group Identifier (default is Site ID)
- `GroupLevel`: Type of Group specified in `GroupID` (Country, Site)
- `Numerator`: Cumulative Number of Event(s) of Interest (in this
  example, number of AEs reported across subjects)
- `Denominator`: Cumulative Time on Study (in days, across subjects)
- `Metric`: Rate of Event(s) of Interest (in this example, number of AEs
  reported over the course of treatment in days)

------------------------------------------------------------------------

#### 3. Create `dfAnalyzed`

The data frame `dfAnalyzed` is derived from `dfTransformed` using an
`Analyze()` function, which incorporates a specific statistical model.
The resulting `dfAnalyzed` data frame will contain site-level analysis
results data. The normal approximation method is the default statistical
model for AE data, so the analysis pipeline runs
[`Analyze_NormalApprox()`](https://gilead-public.github.io/gsm.core/dev/reference/Analyze_NormalApprox.md).
Because the AE metric is a rate (events per day on study) rather than a
proportion, `strType = "rate"` must be specified; the default,
`strType = "binary"`, is intended for proportions.

``` r

dfAnalyzed <- Analyze_NormalApprox(dfTransformed, strType = "rate")
#> `OverallMetric`, `Factor`, and `Score` columns created from normal
#> approximation.
```

Using our example AE data, `dfAnalyzed` contains the following columns:

- `GroupID`: Group Identifier (default is Site ID)
- `GroupLevel`: Type of Group specified in `GroupID` (Country, Site)
- `Numerator`: Cumulative Number of Event(s) of Interest (in this
  example, number of AEs reported across subjects); Carried from
  `dfTransformed`.
- `Denominator`: Cumulative Time on Study (in days, across subjects);
  Carried from `dfTransformed`.
- `Metric`: Rate of Event(s) of Interest (in this example, number of AEs
  reported over the course of treatment in days); Carried from
  `dfTransformed`.
- `OverallMetric`: Aggregate metric for the group that is being
  assessed. ( sum(Numerator) / sum(Denominator) ).
- `Factor`: Over-dispersion adjustment factor (the mean of the squared
  unadjusted z-scores across all groups).
- `Score`: Over-dispersion-adjusted z-score (per site).

------------------------------------------------------------------------

#### 4. Create `dfFlagged`

The data frame `dfFlagged` is derived from `dfAnalyzed` using the
[`Flag()`](https://gilead-public.github.io/gsm.core/dev/reference/Flag.md)
function. The resulting `dfFlagged` data frame will contain site-level
analysis results data with flagging incorporated based on a
pre-specified statistical threshold to highlight possible outliers.

``` r

dfFlagged <- Flag(
  dfAnalyzed,
  vThreshold = c(-2, -1, 2, 3),
  nAccrualThreshold = 30,
  strAccrualMetric = "Denominator"
)
#> ℹ 22 Group(s) have insufficient sample size due to KRI denominator less than 30: 0X7002, 0X7958, 0X3574, 0X8771, 0X9501, 0X1128, 0X9788, 0X2481, 0X3701, 0X1048, 0X4089, 0X2572, 0X1268, 0X7126, 0X2882, 0X7373, 0X3355, 0X3844, 0X5699, 0X3593, 0X3773, 0X3786
#> These group(s) will not have KRI score and flag summarized.
#> ℹ Sorted dfFlagged using custom Flag order: 2.Sorted dfFlagged using custom Flag order: -2.Sorted dfFlagged using custom Flag order: 1.Sorted dfFlagged using custom Flag order: -1.Sorted dfFlagged using custom Flag order: 0.
```

The thresholds above match the AE KRI workflow (`kri0001`) in
`{gsm.kri}`. Note that they differ from the generic
[`Flag()`](https://gilead-public.github.io/gsm.core/dev/reference/Flag.md)
defaults of (-3, -2, 2, 3); the appropriate thresholds depend on the
KRI. Groups whose `Denominator` (here, total days on study) is below
`nAccrualThreshold` are not evaluated, and their `Score` and `Flag` are
set to `NA`. Using our example AE data, `dfFlagged` contains the
following columns:

- `GroupID`: Group Identifier (default is Site ID)
- `GroupLevel`: Type of Group specified in `GroupID` (Country, Site)
- `Numerator`: Cumulative Number of Event(s) of Interest (in this
  example, number of AEs reported across subjects); Carried from
  `dfAnalyzed`
- `Denominator`: Cumulative Time on Study (in days, across subjects);
  Carried from `dfAnalyzed`
- `Metric`: Rate of Event(s) of Interest (in this example, number of AEs
  reported over the course of treatment in days); Carried from
  `dfAnalyzed`
- `OverallMetric`: Aggregate metric for the group that is being
  assessed. ( sum(Numerator) / sum(Denominator) ).
- `Factor`: Over-dispersion adjustment factor (the mean of the squared
  unadjusted z-scores across all groups); Carried from `dfAnalyzed`.
- `Score`: Over-dispersion-adjusted z-score (per site); Carried from
  `dfAnalyzed`
- `Flag`: Flag Indicating Possible Statistical Outliers; Valid values
  for this variable include -2, -1, 0, 1, and 2, which determine the
  “extremeness” of the outlier. -2 and 2 represent more extreme
  outliers, -1 and 1 represent less extreme outliers, 0 represents a
  non-outlier, and `NA` indicates the group did not meet the accrual
  threshold.

------------------------------------------------------------------------

#### 5. Create `dfSummary`

The data frame `dfSummary` is derived from `dfFlagged` using the
[`Summarize()`](https://gilead-public.github.io/gsm.core/dev/reference/Summarize.md)
function. The resulting `dfSummary` data frame will contain the most
relevant columns from `dfFlagged` with data sorted in a meaningful way
to provide a concise overview of the assessment. Flagged sites will sort
earlier than non-flagged sites, in the flag order 2, -2, 1, -1, 0;
within each flag level, sites are sorted by descending absolute `Metric`
(not by `Score`). The columns in `dfSummary` include:

- `GroupID`: Group Identifier (default is Site ID)
- `GroupLevel`: Type of Group specified in `GroupID` (Country, Site)
- `Numerator`: Cumulative Number of Event(s) of Interest (in this
  example, number of AEs reported across subjects); Carried from
  `dfFlagged`
- `Denominator`: Cumulative Time on Study (in days, across subjects);
  Carried from `dfFlagged`
- `Metric`: Rate of Event(s) of Interest (in this example, number of AEs
  reported over the course of treatment in days)
- `Score`: Over-dispersion-adjusted z-score (per site)
- `Flag`: Flag Indicating Possible Statistical Outliers; Valid values
  for this variable include -2, -1, 0, 1, and 2, which determine the
  “extremeness” of the outlier. -2 and 2 represent more extreme
  outliers, -1 and 1 represent less extreme outliers, 0 represents a
  non-outlier, and `NA` indicates the group did not meet the accrual
  threshold.

``` r

dfSummary <- Summarize(dfFlagged)
```

------------------------------------------------------------------------

## Recap - Normal Approximation Adverse Event KRI

- `dfInput` used as original input using
  [`Input_Rate()`](https://gilead-public.github.io/gsm.core/dev/reference/Input_Rate.md)
- `dfTransformed` created from `dfInput` using
  [`Transform_Rate()`](https://gilead-public.github.io/gsm.core/dev/reference/Transform_Rate.md)
- `dfAnalyzed` created from `dfTransformed` using
  `Analyze_NormalApprox(strType = "rate")`
- `dfFlagged` created from `dfAnalyzed` using
  [`Flag()`](https://gilead-public.github.io/gsm.core/dev/reference/Flag.md)
- `dfSummary` created from `dfFlagged` using
  [`Summarize()`](https://gilead-public.github.io/gsm.core/dev/reference/Summarize.md)

------------------------------------------------------------------------

## Appendix 1 - Supporting Functions

The following sections include various examples of supporting functions
and statistical models that can be employed in the Analysis workflow.
Please note that this is **not** an exhaustive list, but includes some
of the most commonly called upon functions.

#### Mapping Functions

- [`workr::RunQuery()`](https://rdrr.io/pkg/workr/man/RunQuery.html):
  Run a SQL query to create new data.frames with filtering and column
  name specifications.
  ([`gsm.core::RunQuery()`](https://gilead-public.github.io/gsm.core/dev/reference/RunQuery.md)
  is a deprecated wrapper for this function.)
- [`Input_Rate()`](https://gilead-public.github.io/gsm.core/dev/reference/Input_Rate.md):
  Calculate a subject level rate from raw numerator and denominator data

#### Transform Functions

- [`Transform_Rate()`](https://gilead-public.github.io/gsm.core/dev/reference/Transform_Rate.md):
  Calculates cumulative rate of Event(s) of Interest per site
- [`Transform_Count()`](https://gilead-public.github.io/gsm.core/dev/reference/Transform_Count.md):
  Calculates cumulative number of Event(s) of Interest per site

#### Analyze Functions

- [`Analyze_NormalApprox()`](https://gilead-public.github.io/gsm.core/dev/reference/Analyze_NormalApprox.md):
  Uses funnel plot method with normal approximation to create analysis
  results for percentage/rate.
- [`Analyze_Fisher()`](https://gilead-public.github.io/gsm.core/dev/reference/Analyze_Fisher.md):
  Uses Fisher’s Exact Test to determine if there are non-random
  associations between a site and a given KRI
- [`Analyze_Identity()`](https://gilead-public.github.io/gsm.core/dev/reference/Analyze_Identity.md):
  Used in the data pipeline between `Transform()` and
  [`Flag()`](https://gilead-public.github.io/gsm.core/dev/reference/Flag.md)
  functions to rename the metric and score columns
- [`Analyze_Poisson()`](https://gilead-public.github.io/gsm.core/dev/reference/Analyze_Poisson.md):
  Uses a Poisson model to describe the distribution of events in the
  overall site population, i.e., determine how many times an event is
  likely to occur at a site over a specified treatment period

#### Flag Functions

- [`Flag()`](https://gilead-public.github.io/gsm.core/dev/reference/Flag.md):
  Default flagging function for all assessments
- [`Flag_NormalApprox()`](https://gilead-public.github.io/gsm.core/dev/reference/Flag_NormalApprox.md):
  Alias for
  [`Flag()`](https://gilead-public.github.io/gsm.core/dev/reference/Flag.md),
  retained for backward compatibility; use
  [`Flag()`](https://gilead-public.github.io/gsm.core/dev/reference/Flag.md)
  instead.
- [`Flag_Poisson()`](https://gilead-public.github.io/gsm.core/dev/reference/Flag_Poisson.md):
  Alias for
  [`Flag()`](https://gilead-public.github.io/gsm.core/dev/reference/Flag.md),
  retained for backward compatibility; use
  [`Flag()`](https://gilead-public.github.io/gsm.core/dev/reference/Flag.md)
  instead.

#### What Statistical Models Are Available For Each Assessment?

- Most yaml workflow assessments in the `inst/workflow/2_metrics`
  directory of the `{gsm.kri}` package use the [normal
  approximation](https://gilead-public.github.io/gsm.core/articles/KRIMethod.html#the-normal-approximation-method)
  method; the remaining ones use the
  [**Identity**](https://gilead-public.github.io/gsm.core/articles/KRIMethod.html#the-identity-method)
  method.
- [gsm.core](https://gilead-public.github.io/gsm.core) also provides the
  [**Poisson**](https://gilead-public.github.io/gsm.core/articles/KRIMethod.html#the-poisson-regression-method)
  and [**Fisher’s
  Exact**](https://gilead-public.github.io/gsm.core/articles/KRIMethod.html#the-fishers-exact-method)
  methods, which are not used by the standard `{gsm.kri}` KRIs.

``` mermaid

flowchart TB
  subgraph normal ["Normal Approximation (binary or rate KRIs)"]
    direction LR
    n1[dfInput] -->|"Transform_Rate()"| n2[dfTransformed]
    n2 -->|"Analyze_NormalApprox(strType)"| n3[dfAnalyzed]
    n3 -->|"Flag()"| n4[dfFlagged]
    n4 -->|"Summarize()"| n5[dfSummary]
  end

  subgraph identity ["Identity"]
    direction LR
    i1[dfInput] -->|"Transform_Rate() or<br>Transform_Count() *"| i2[dfTransformed]
    i2 -->|"Analyze_Identity()"| i3[dfAnalyzed]
    i3 -->|"Flag()"| i4[dfFlagged]
    i4 -->|"Summarize()"| i5[dfSummary]
  end

  subgraph poisson ["Poisson"]
    direction LR
    p1[dfInput] -->|"Transform_Rate()"| p2[dfTransformed]
    p2 -->|"Analyze_Poisson()"| p3[dfAnalyzed]
    p3 -->|"Flag()<br>residual thresholds"| p4[dfFlagged]
    p4 -->|"Summarize()"| p5[dfSummary]
  end

  subgraph fisher ["Fisher's Exact"]
    direction LR
    f1[dfInput] -->|"Transform_Rate()"| f2[dfTransformed]
    f2 -->|"Analyze_Fisher()"| f3[dfAnalyzed]
    f3 -->|"Flag()<br>p-value thresholds"| f4[dfFlagged]
    f4 -->|"Summarize() *"| f5[dfSummary]
  end

  normal ~~~ identity ~~~ poisson ~~~ fisher

  style normal fill:#fff8e1,stroke:#ffc000
  style identity fill:#fdeee4,stroke:#ed7d31
  style poisson fill:#eaf1fb,stroke:#5b9bd5
  style fisher fill:#eef6e9,stroke:#70ad47
```

\*
[`Transform_Count()`](https://gilead-public.github.io/gsm.core/dev/reference/Transform_Count.md)
and
[`Analyze_Fisher()`](https://gilead-public.github.io/gsm.core/dev/reference/Analyze_Fisher.md)
do not return a `GroupLevel` column, which
[`Summarize()`](https://gilead-public.github.io/gsm.core/dev/reference/Summarize.md)
requires; add it (e.g. `dplyr::mutate(GroupLevel = "Site")`) before
calling
[`Summarize()`](https://gilead-public.github.io/gsm.core/dev/reference/Summarize.md).
