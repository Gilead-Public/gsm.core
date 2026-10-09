# KRI Method

## Overview

This vignette outlines the statistical methods used to evaluate Key Risk
Indicators (KRIs) in the {gsm} suite of packages. KRIs are metrics that
allow users to measure pre-defined risks and determine the level of
observed risk to data quality and patient safety in a clinical trial.
The {gsm} suite of packages implements a standardized data pipeline to
facilitate KRI analysis. Other vignettes provide an overview of this
framework
([1](https://gilead-public.github.io/gsm.kri/examples/Cookbook_AdverseEventKRI.html),
[2](https://gilead-public.github.io/gsm.core/dev/articles/DataModel.md),
[3](https://gilead-public.github.io/gsm.core/dev/articles/DataAnalysis.md),
[4](https://gilead-public.github.io/gsm.reporting/articles/DataReporting.html)),
and the statistical methods for this process are described in detail
below.

[gsm.core](https://gilead-public.github.io/gsm.core) calculates KRIs by
defining a numerator and a denominator for each metric. Then by default,
[gsm.core](https://gilead-public.github.io/gsm.core) calculates z-scores
using a normal approximation with adjustment for over-dispersion to
assign risk levels.

For KRIs that are percentages (binary outcome), the numerator is the \#
of events and the denominator is the \# of total participants, and we
then apply the normal approximation of the binomial distribution to
determine a risk level.

For KRIs that are rates (count outcome), the numerator is the \# of
events and the denominator is the total participant exposure or study
duration, and we then apply the normal approximation of the Poisson
distribution to determine a risk level.

Alternative statistical methods to calculate standardized scores are
also available in [gsm.core](https://gilead-public.github.io/gsm.core),
including the Identity, Fisher and Poisson methods. More details are
provided below.

## Statistical Methods

### 1. The Normal Approximation Method

#### Introduction

This method applies normal approximation of binomial distribution to the
binary outcome KRIs, or normal approximation of Poisson distribution for
the rate outcome KRIs (the sample sizes or total exposure of the sites)
to assess data quality and safety. The control limits based on the
asymptotic normal approximation are constructed to as risk thresholds
for identifying site-level risks.

Reference: Zink, Richard C., Anastasia Dmitrienko, and Alex Dmitrienko.
**Rethinking the clinically based thresholds of TransCelerate BioPharma
for risk-based monitoring.** *Therapeutic Innovation & Regulatory
Science* 52, no. 5 (2018): 560-571.

#### Methods

##### Binary

Consider the problem of monitoring KRIs with binary outcomes, such as
protocol deviation or discontinuation from the study, across multiple
sites in a clinical trial. Assume that there are $`m`$ sites with
$`n_i`$ patients at the $`i`$ th site, $`i = 1, 2, \dots, m`$. Denote
the total number of patients in the study by $`n=\sum_{i=1}^m n_i`$. Let
$`X_{ij}`$ signify the outcome of interest for the $`j`$ th patient at
the $`i`$ th site, where $`X_{ij}=1`$ indicates that an event has
occurred and $`X_{ij}=0`$ indicates that an event has not occurred.
Finally, let $`p_i`$ denote the site-level proportion at the $`i`$ th
site. Monitoring tools focus on testing the null hypothesis of
consistency of the true site-level proportion across multiple sites.
Specifically, the null hypothesis states that the site-level proportion
of the binary outcome is constant across the sites, that is,
$`H_0: p_1 = \dots = p_m = p`$, where $`p`$ is the common proportion.
This common proportion can be estimated as
$`\hat{p} = \frac{1}{n}\sum_{i=1}^m\sum_{j=1}^{n_i}X_{ij}`$.

The control limits are computed using confidence limits based on an
asymptotic normal approximation. A 95% confidence interval is obtained
if the significance level $`\alpha=0.05`$. Let
$`X_i=\sum_{j=1}^{n_i}X_{ij}`$ represent the total number of events that
occur and let $`\hat{p}_i=X_i/n_i`$ denote the estimated event rate at
the $`i`$ th site. The asymptotic $`100(1 – \alpha)%`$ confidence
interval for $`p_i`$ is given by
``` math
\hat{p}_i-z_{1-\alpha/2}\sqrt{\frac{\hat{p}_i(1-\hat{p}_i)}{n_i}} \leq p_i \leq \hat{p}_i+z_{1-\alpha/2}\sqrt{\frac{\hat{p}_i(1-\hat{p}_i)}{n_i}}
```
where $`z_{1-\alpha/2}`$ is the upper $`\alpha/2`$ quantile of the
standard normal distribution. To construct the control limits for the
observed event rate at this site, the estimated event rate is forced to
be equal to the overall event rate $`\hat{p}`$. This means that the
lower (l) and upper (u) asymptotic control limits for the $`i`$ th site
are defined as
$`l_i=\hat{p}-z_{1-\alpha/2}\sqrt{\frac{\hat{p}(1-\hat{p})}{n_i}}`$ and
$`u_i=\hat{p}+z_{1-\alpha/2}\sqrt{\frac{\hat{p}(1-\hat{p})}{n_i}}`$,
respectively. Asymptotic control limits may not be reliable in smaller
clinical trials, so exact limits for an event rate may be preferable.

##### Rate

Assume that the distribution of number of events up to time $`T`$ is
Poisson with mean $`\lambda T`$, where $`\lambda`$ is the event rate for
a given unit of time. For the $`i`$ th site with
$`X_i=\sum_{j=1}^{n_i}X_{ij}`$ events and $`T_i=\sum_{j=1}^{n_i}t_{ij}`$
exposure, define the exposure-adjusted incidence rate (EAIR) as
$`\hat{\lambda}_i=\frac{X_i}{T_i}`$. For all sites, define
$`X=\sum_{i=1}^{m}X_{i}`$ and $`T=\sum_{i=1}^{m}T_{i}`$ with
$`\hat{\lambda}=\frac{X}{T}`$. Under a normal approximation,
$`100(1 – \alpha)%`$ confidence interval for the $`i`$ th site is
``` math
\hat{\lambda}_i-z_{1-\alpha/2}\sqrt{\frac{\hat{\lambda}_i}{T_i}} \leq \lambda_i \leq \hat{\lambda}_i+z_{1-\alpha/2}\sqrt{\frac{\hat{\lambda}_i}{T_i}}
```
. For these funnel plots accounting for exposure, the x-axis
representing the site sample size ($`n_i`$) in the binary case is
replaced by the total exposure time $`T_i`$. To develop a funnel plot,
fix $`\hat{\lambda}_i=\hat{\lambda}`$, and vary $`T`$ from $`min(T_i)`$
to $`max(T_i)`$ to compute the control limits. Finally, similar methods
can be applied for a count-type endpoint $`X_{ij}`$, where $`t_{ij}`$
would denote the time on study for the $`j`$ th patient at the $`i`$ th
site.

#### KRI Metric and Z-score

The KRI metric along with a KRI score are created for each site to
measure the level of observed risk to data quality and patient safety in
a clinical trial. For scoring purposes, Z-scores from the normal
approximation are calculated and defined as such:
$`z_{0,i}=\frac{y_i-\theta_0}{\sqrt{V(Y|\theta_0)}}`$ for site $`i`$,
where $`y_i`$ is the KRI metric calculated for site $`i`$, $`\theta_0`$
is the overall (pooled) metric across all sites, i.e. the sum of all
numerators divided by the sum of all denominators (returned as
`OverallMetric`), and $`\sqrt{V(Y|\theta_0)}`$ is the standard deviation
of the metric under the null.

For binary outcome,
$`\sqrt{V(Y|\theta_0)}=\sqrt{\frac{\hat{p}(1-\hat{p})}{n_i}}`$.

For rate outcome,
$`\sqrt{V(Y|\theta_0)}=\sqrt{\frac{\hat{\lambda}}{T_i}}`$.

#### Over-dispersion adjustment

The standard normal approximation method described above assumes the
null distribution fully expresses the variability of the sites
in-control, but in many situations this assumption will not hold. In the
situation that there is a presence of greater variability than expected,
an excess of sites will fall outside the specified limits, leading to a
doubt of the appropriateness of the constructed limits.

A way of handling this issue is to allow over-dispersion in the normal
approximation. A multiplicative over-dispersion adjustment was
implemented in our approach.

Following Spiegelhalter (2005), the over-dispersion factor $`\phi`$ is
estimated as the mean of the squared unadjusted z-scores $`z_{0,i}`$ (as
defined in the previous section), i.e.,
$`\hat\phi = \frac{1}{m}\sum_{i=1}^m z_{0,i}^2`$. In
[gsm.core](https://gilead-public.github.io/gsm.core), all $`m`$ sites
are used for this estimate (no subset of in-control sites is identified
and no winsorization is applied), and $`\hat\phi`$ is applied whether it
is above or below 1. For binary outcome, the over-dispersion adjusted
variance is $`V'(Y_i|\phi, p)=\phi\frac{{p}(1-p)}{n_i}`$. For rate
outcome, the over-dispersion adjusted variance is
$`V'(Y_i|\phi, \lambda)=\phi\frac{\lambda}{T_i}`$. Therefore, after the
over-dispersion adjustment, the adjusted z-scores for site $`i`$ are
$`z_i = \frac{\hat{p}_i - \hat{p}}{\sqrt{\hat\phi \frac{{\hat{p}}(1-\hat{p})}{n_i}}}`$,
$`z_i = \frac{\hat{\lambda}_i - \hat{\lambda}}{\sqrt{\hat\phi \frac{\hat\lambda}{T_i}}}`$,
respectively, i.e., $`z_i = z_{0,i}/\sqrt{\hat\phi}`$.

Reference: Spiegelhalter, David J. **Funnel plots for comparing
institutional performance.** *Statistics in medicine* 24.8 (2005):
1185-1202.

#### Estimate and Score

The function
[`Analyze_NormalApprox()`](https://gilead-public.github.io/gsm.core/dev/reference/Analyze_NormalApprox.md)
in [gsm.core](https://gilead-public.github.io/gsm.core) calculates
adjusted z-score for each site as discussed above. The adjusted z-scores
are then used as a scoring metric in
[gsm.core](https://gilead-public.github.io/gsm.core) to flag possible
outliers using the thresholds discussed below.

#### Threshold

By default
([`Flag()`](https://gilead-public.github.io/gsm.core/dev/reference/Flag.md)
with `vThreshold = c(-3, -2, 2, 3)`), sites with adjusted z-score at or
beyond $`\pm 2`$ or $`\pm 3`$ from the normal approximation analysis are
flagged as amber or red, respectively. The thresholds are set at common
choices corresponding to approximately 95.45% and 99.73% of the data
around the mean in a standard normal distribution. However, they are
fully configurable in the package and can be customized and specified in
the [gsm.core](https://gilead-public.github.io/gsm.core) functions.

#### Special Situations

1.  Results are not interpretable or it is not appropriate to apply the
    asymptotic method: We don’t want to flag in certain situations when
    results not interpretable or when it is not appropriate to apply the
    asymptotic method due to the small sample sizes. A minimum accrual
    requirement can be set via the `nAccrualThreshold` and
    `strAccrualMetric` arguments of
    [`Flag()`](https://gilead-public.github.io/gsm.core/dev/reference/Flag.md)
    (no minimum is applied by default in
    [gsm.core](https://gilead-public.github.io/gsm.core)); the
    `{gsm.kri}` workflows typically use 30 days exposure for rate KRIs
    or 3 patients for binary KRIs at the site level.

#### Recommendation

Normal approximation method can be used in all scenarios with binary or
rate KRIs.

### 2. The Identity Method

Identity method simply uses a column of the transformed data itself as
the score: the KRI `Metric` by default, configurable via the
`strValueCol` argument of
[`Analyze_Identity()`](https://gilead-public.github.io/gsm.core/dev/reference/Analyze_Identity.md).
The thresholds for monitoring site risk are set on the scale of that
column (e.g., the actual counts).

### 3. The Fisher’s Exact Method

#### Introduction

For the binary outcome KRIs, an optional method in
[gsm.core](https://gilead-public.github.io/gsm.core) is implemented with
Fisher’s exact test.

Fisher’s exact test is a statistical significance test used in the
analysis of contingency tables when we have nominal variables and want
to find out if proportions for one variable are different among values
of the other variables.

In contrast to large-sample based asymptotic statistics which rely on
approximation, Fisher’s exact test can be applied when sample sizes are
small.

The function `Analyze_Fisher` in
[gsm.core](https://gilead-public.github.io/gsm.core) utilizes
[`stats::fisher.test`](https://rdrr.io/r/stats/fisher.test.html) to
generate an estimate of odds ratio as well as p-value using the Fisher’s
exact test with site-level count data. For each site, Fisher’s exact
test is conducted by comparing to all other sites combined in a 2×2
contingency table. The p-values are then used as a scoring metric in
[gsm.core](https://gilead-public.github.io/gsm.core) to flag possible
outliers. The default in
[`stats::fisher.test`](https://rdrr.io/r/stats/fisher.test.html) uses a
two-sided test (equivalent to testing the null of OR = 1) and does not
compute p-values by Monte Carlo simulation unless
`simulate.p.value = TRUE`. Flagging thresholds for the p-values must be
specified explicitly (see below).

#### Methods

For example, in a $`2 \times 2`$ contingency table comparing a
particular site to all other sites combined, the two columns (the site
and all other sites combined) are considered independent binomial
samples of the binary outcome with a common, unknown probability $`p`$
of success under the null. Given a $`2 \times 2`$ contingency table,

| Site1 | RestSites |
|-------|-----------|
| a     | c         |
| b     | d         |

Fisher (1922) showed that conditional on the margins of the table, $`a`$
is distributed as a hypergeometric distribution with $`a+c`$ draws from
a population with $`a+b`$ successes and $`c+d`$ failures. Let
$`n=a+b+c+d`$, the probability of obtaining such set of values is given
by:

``` math
p=\frac{{{a+b} \choose a} {{c+d} \choose c}}{{n \choose {a+c}}}=\frac{{{a+b} \choose b} {{c+d} \choose d}}{{n \choose {b+d}}}=\frac{(a+b)!(c+d)!(a+c)!(b+d)!}{a! b! c! d! n!}.
```

#### Estimate and Score

The function
[`Analyze_Fisher()`](https://gilead-public.github.io/gsm.core/dev/reference/Analyze_Fisher.md)
in [gsm.core](https://gilead-public.github.io/gsm.core) utilizes
[`stats::fisher.test()`](https://rdrr.io/r/stats/fisher.test.html) to
generate an estimate of odds ratio as well as p-value using the Fisher’s
exact test with site-level count data. For each site, Fisher’s exact
test is conducted by comparing to all other sites combined in a
$`2 \times 2`$ contingency table. The p-values are then used as a
scoring metric in [gsm.core](https://gilead-public.github.io/gsm.core)
to flag possible outliers using the thresholds discussed below. The
default in
[`stats::fisher.test()`](https://rdrr.io/r/stats/fisher.test.html) uses
two-sided test (equivalent to testing the null: OR=1) and not to compute
p-values by Monte Carlo simulation unless `simulate.p.value = TRUE` is
specified.

#### Threshold

There are no Fisher-specific default thresholds:
[`Flag()`](https://gilead-public.github.io/gsm.core/dev/reference/Flag.md)
defaults to `vThreshold = c(-3, -2, 2, 3)`, which never flags p-values
(between 0 and 1). Thresholds must therefore be specified explicitly.
Common choices of significance levels are p-values less than 0.05 or
0.01, flagged as amber or red, respectively; alternatively, the
distribution of the p-values can be used to find the best separation of
the data to identify sites at risk. For example:

``` r

dfTransformed <- Transform_Rate(analyticsInput)
#> Warning: 1 values of [ GroupID ] with a [ Denominator ] value of 0
#> removed.
dfAnalyzed <- Analyze_Fisher(dfTransformed)
dfFlagged <- Flag(
  dfAnalyzed,
  vThreshold = c(0.01, 0.05),
  vFlag = c(2, 1, 0),
  vFlagOrder = c(2, 1, 0)
)
head(dfFlagged[, c("GroupID", "Prop", "Prop_Other", "Score", "Flag")])
#> # A tibble: 6 × 5
#>   GroupID  Prop Prop_Other     Score  Flag
#>   <chr>   <dbl>      <dbl>     <dbl> <dbl>
#> 1 0X3773  0.714     0.0835 0.0000741     2
#> 2 0X8743  0.267     0.0834 0.00260       2
#> 3 0X2413  0.146     0.0832 0.00535       2
#> 4 0X7497  0.174     0.0834 0.00542       2
#> 5 0X3355  0.259     0.0835 0.00565       2
#> 6 0X4264  0.123     0.0831 0.0110        1
```

Note that the two-sided p-values do not indicate the direction of the
difference; compare the site proportion (`Prop`) with that of all other
sites (`Prop_Other`) to determine whether a flagged site is above or
below the rest of the study.

#### The Fisher’s exact test assumptions

1.  The row totals and the column totals are both fixed by design.

2.  The samples are mutually exclusive and mutually independent.

The assumptions can be assessed by the knowledge of data collected. No
assumption check is necessary.

#### Special situations

1.  Functionally: where we don’t have required input to run Fishers:
    p-value will be set `NA`.

2.  Results not interpretable: we don’t want to flag in certain
    situations when results not interpretable due to small sample sizes.
    A minimum denominator requirement (e.g., 3 patients at the site
    level) can be set via the `nAccrualThreshold` and `strAccrualMetric`
    arguments of
    [`Flag()`](https://gilead-public.github.io/gsm.core/dev/reference/Flag.md);
    no minimum is applied by default.

3.  An observed zero cell is not an issue when using Fisher’s exact
    test, however, when the expected cell is zero, it means either the
    marginal is zero (meaningless) or there are structural zeros (need
    to consider zero-inflated issue: West, L. and Hankin, R. (2008),
    “Exact Tests for Two-Way Contingency Tables with Structural Zeros,”
    Journal of Statistical Software, 28(11), 1–19).

#### Constraints

For small samples, Fisher’s exact test is highly discrete. Fisher’s
exact test is often considered to be more conservative. This may due to
the use a discrete statistic with fixed significance levels ([FET
Controversies
Wiki](https://en.wikipedia.org/wiki/Fisher%27s_exact_test#Controversies)).

Although in practice, Fisher’s exact test is usually used when sample
sizes are small (e.g., expected cell counts \<5), it is valid for all
sample sizes. However, when sample sizes are large, the computation of
the exact test evaluating the hypergeometric probability function given
the marginal can take a very long time.

#### Recommendation

Fisher’s exact test can be used in all scenarios with binary KRIs.

### 4. The Poisson Regression Method

#### Introduction

For the rate outcome KRIs, an optional method in
[gsm.core](https://gilead-public.github.io/gsm.core) is implemented with
Poisson regression.

The Poisson distribution is often used to model count data. If $`Y`$ is
the number of counts following Poisson distribution, the probability
mass function is given by
``` math
f(y)=\frac{\mu^ye^{-\mu}}{y!}
```
where $`\mu`$ is the average number of counts and $`E(Y)=Var(Y)=\mu`$.

#### Methods

This method fits a Poisson model to site-level data and then calculates
deviance residuals for each site. The Poisson model is run using
standard methods in the `stats` package by fitting a `glm` model with
family set to `poisson` using a “log” link. Site-level deviance
residuals (the
[`broom::augment()`](https://generics.r-lib.org/reference/augment.html)
default, equivalent to `stats::residuals(type = "deviance")`) and fitted
values (via
[`stats::predict.glm()`](https://rdrr.io/r/stats/predict.glm.html)) are
calculated using
[`broom::augment()`](https://generics.r-lib.org/reference/augment.html).

Let $`Y_1, ..., Y_m`$ be independent random variables with
$`Y_i \sim Poisson(\mu_i)`$ denoting the number of events (`Numerator`)
observed at the $`i`$th site with total exposure $`T_i`$
(`Denominator`). Then $`E(Y_i)=\mu_i=T_ie^{\beta_0}`$. Thus, the
log-linear generalized linear model (Poisson regression) fitted in
[gsm.core](https://gilead-public.github.io/gsm.core) is the
intercept-only model
``` math
\log{\mu_i}=\log{T_i}+\beta_0 \quad Y_i \sim Poisson(\mu_i)
```

where $`\log{T_i}`$ is an offset term and $`e^{\beta_0}`$ is the overall
event rate.

#### Estimate and Score

The function
[`Analyze_Poisson()`](https://gilead-public.github.io/gsm.core/dev/reference/Analyze_Poisson.md)
in [gsm.core](https://gilead-public.github.io/gsm.core) utilizes
[`stats::glm()`](https://rdrr.io/r/stats/glm.html) to generate an
estimate of fitted values as well as deviance residual with site-level
count data. The deviance residuals are then used as a scoring metric in
[gsm.core](https://gilead-public.github.io/gsm.core) to flag possible
outliers using the thresholds discussed below.

#### Threshold

There are no Poisson-specific default thresholds in
[`Flag()`](https://gilead-public.github.io/gsm.core/dev/reference/Flag.md)
(or its alias
[`Flag_Poisson()`](https://gilead-public.github.io/gsm.core/dev/reference/Flag_Poisson.md)),
which defaults to `vThreshold = c(-3, -2, 2, 3)`; thresholds for
deviance residuals should therefore be specified explicitly. Empirical
values based on pilot studies’ data are deviance residuals at or beyond
$`\pm 5`$ or $`\pm 7`$, flagged as amber or red, respectively (e.g.,
`Flag(dfAnalyzed, vThreshold = c(-7, -5, 5, 7))`). These thresholds are
set based on an empirical approach, where we use the distribution of the
deviance residuals to find the best separation of the data to identify
sites at risk. They are fully configurable and can be customized in the
[gsm.core](https://gilead-public.github.io/gsm.core) functions.

#### Special Situations

1.  Results are not interpretable or it is not appropriate to apply the
    Poisson method: We don’t want to flag in certain situations when
    results not interpretable or when it is not appropriate to apply the
    Poisson method due to the small sample sizes. A minimum denominator
    requirement (e.g., 30 days exposure at the site level) can be set
    via the `nAccrualThreshold` and `strAccrualMetric` arguments of
    [`Flag()`](https://gilead-public.github.io/gsm.core/dev/reference/Flag.md);
    no minimum is applied by default.

#### Poisson regression assumptions

1.  **Independence** The responses $`y_i`$ are independent of each
    other.

2.  **Count data** The responses $`y_i`$ are non-negative integer
    (counts).

3.  **Poisson response** Each $`Y_i`$ follows the Poisson distribution
    as noted above with mean and variance equal to $`\mu_i`$.

4.  **Linearity** $`\log{\mu_i}=\log{T_i}+\beta_0`$, i.e., the expected
    count is proportional to exposure, with a common event rate across
    sites under the null.

#### Assumption checks, constraints and model diagnosis

1.  The assumptions on independence and counted data can be assessed by
    the knowledge of data collected.

2.  The assumptions on Poisson response can be checked by plotting
    histogram of the data and comparing empirical mean and variance
    stratified by the explanatory variable(s). If there is evidence that
    the assumption of mean=variance is violated, oftentimes we observe
    variance\>mean. This is called overdispersion. In this case, a
    quasi-Poisson model, where $`Var(Y_i)=\phi E(Y_i)`$, or a negative
    binomial model, where $`Var(Y_i)=\mu_i+\mu_i^2/k`$, provides an
    alternative.

3.  Diagnosis: Goodness of fit test (chi-squared) and deviance
    residuals. Residuals vs fitted plot. Q-Q plot.

4.  Other considerations: Structural zeros may happen in contrast to
    random zeros due to sampling from poisson distribution. In this
    case, a mixture model (zero-inflated Poisson model) may be required.

#### Recommendation

Use this method when Poisson assumptions hold.
