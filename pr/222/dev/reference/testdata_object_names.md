# List test data object names

**\[experimental\]**

## Usage

``` r
testdata_object_names()
```

## Value

`character` Object names.

## Details

Names of the test data objects (e.g.
[lSource](https://gilead-public.github.io/gsm.core/dev/reference/lSource.md))
that gsm.core serves from gsm.datasim test data releases.

## Examples

``` r
testdata_object_names()
#>  [1] "lSource"                  "analyticsInput"          
#>  [3] "analyticsSummary"         "reportingResults"        
#>  [5] "reportingGroups"          "reportingBounds"         
#>  [7] "reportingMetrics"         "reportingResults_country"
#>  [9] "reportingGroups_country"  "reportingBounds_country" 
#> [11] "reportingMetrics_country" "reportingResults_study"  
#> [13] "reportingGroups_study"    "reportingBounds_study"   
#> [15] "reportingMetrics_study"  
```
