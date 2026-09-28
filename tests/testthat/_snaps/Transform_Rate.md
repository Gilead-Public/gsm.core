# rows with a denominator of 0 are removed

    Code
      row_removed
    Output
      # A tibble: 149 x 5
         GroupID GroupLevel Numerator Denominator Metric
         <chr>   <chr>          <int>       <dbl>  <dbl>
       1 0X065   Site              25         122  0.205
       2 0X083   Site              19          61  0.311
       3 0X1078  Site               7          41  0.171
       4 0X1130  Site               5           1  5    
       5 0X1134  Site              24          67  0.358
       6 0X1201  Site              24         113  0.212
       7 0X1338  Site               8          47  0.170
       8 0X1387  Site              10          71  0.141
       9 0X1417  Site               6          26  0.231
      10 0X1419  Site              23         120  0.192
      # i 139 more rows

