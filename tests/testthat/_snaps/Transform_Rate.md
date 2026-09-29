# rows with a denominator of 0 are removed

    Code
      row_removed
    Output
      # A tibble: 144 x 5
         GroupID GroupLevel Numerator Denominator Metric
         <chr>   <chr>          <int>       <dbl>  <dbl>
       1 0X020   Site               3          26 0.115 
       2 0X077   Site               1          19 0.0526
       3 0X1012  Site              23         266 0.0865
       4 0X108   Site              51         600 0.085 
       5 0X1154  Site              21         230 0.0913
       6 0X1167  Site               9         107 0.0841
       7 0X1175  Site              14         140 0.1   
       8 0X1185  Site              38         402 0.0945
       9 0X1302  Site               1          12 0.0833
      10 0X1319  Site               5          56 0.0893
      # i 134 more rows

