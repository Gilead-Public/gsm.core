# rows with a denominator of 0 are removed

    Code
      row_removed
    Output
      # A tibble: 144 x 5
         GroupID GroupLevel Numerator Denominator Metric
         <chr>   <chr>          <int>       <dbl>  <dbl>
       1 0X031   Site               2          27 0.0741
       2 0X103   Site               1          11 0.0909
       3 0X1091  Site               6          22 0.273 
       4 0X126   Site              10         178 0.0562
       5 0X1284  Site              23         337 0.0682
       6 0X1347  Site              38         361 0.105 
       7 0X1437  Site              45         561 0.0802
       8 0X1589  Site               2          34 0.0588
       9 0X1675  Site              39         511 0.0763
      10 0X1755  Site               3          96 0.0312
      # i 134 more rows

