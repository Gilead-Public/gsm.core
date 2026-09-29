# rows with a denominator of 0 are removed

    Code
      row_removed
    Output
      # A tibble: 143 x 5
         GroupID GroupLevel Numerator Denominator Metric
         <chr>   <chr>          <int>       <dbl>  <dbl>
       1 0X092   Site              20         253 0.0791
       2 0X101   Site              35         365 0.0959
       3 0X1093  Site               3          22 0.136 
       4 0X1101  Site               4          43 0.0930
       5 0X1257  Site              19         275 0.0691
       6 0X1267  Site               2          21 0.0952
       7 0X1444  Site              13         154 0.0844
       8 0X1495  Site              23         235 0.0979
       9 0X1650  Site               0           9 0     
      10 0X1696  Site              15         212 0.0708
      # i 133 more rows

