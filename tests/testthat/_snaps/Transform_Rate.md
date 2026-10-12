# rows with a denominator of 0 are removed

    Code
      row_removed
    Output
      # A tibble: 140 x 5
         GroupID GroupLevel Numerator Denominator Metric
         <chr>   <chr>          <int>       <dbl>  <dbl>
       1 0X002   Site               0          16 0     
       2 0X012   Site               0          10 0     
       3 0X094   Site               2          52 0.0385
       4 0X1010  Site              17         205 0.0829
       5 0X1211  Site               3          19 0.158 
       6 0X1259  Site               1           6 0.167 
       7 0X1274  Site              12         195 0.0615
       8 0X1275  Site               5          71 0.0704
       9 0X1284  Site              27         458 0.0590
      10 0X1347  Site              27         375 0.072 
      # i 130 more rows

