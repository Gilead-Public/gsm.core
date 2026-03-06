# rows with a denominator of 0 are removed

    Code
      row_removed
    Output
      # A tibble: 142 x 5
         GroupID GroupLevel Numerator Denominator Metric
         <chr>   <chr>          <int>       <dbl>  <dbl>
       1 0X088   Site               5          41 0.122 
       2 0X101   Site              10         127 0.0787
       3 0X1098  Site              10         140 0.0714
       4 0X1169  Site               4          23 0.174 
       5 0X1257  Site              21         195 0.108 
       6 0X1333  Site               2          23 0.0870
       7 0X1337  Site              11          69 0.159 
       8 0X1417  Site              16         212 0.0755
       9 0X1419  Site               0          24 0     
      10 0X1616  Site               7          89 0.0787
      # i 132 more rows

