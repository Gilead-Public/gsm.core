# rows with a denominator of 0 are removed

    Code
      row_removed
    Output
      # A tibble: 145 x 5
         GroupID GroupLevel Numerator Denominator Metric
         <chr>   <chr>          <int>       <dbl>  <dbl>
       1 0X101   Site              24         231 0.104 
       2 0X1150  Site              12         101 0.119 
       3 0X1240  Site              13         124 0.105 
       4 0X1257  Site              15         175 0.0857
       5 0X1359  Site               4          63 0.0635
       6 0X1405  Site              27         218 0.124 
       7 0X1487  Site              16         266 0.0602
       8 0X1509  Site              15         141 0.106 
       9 0X1548  Site              19         198 0.0960
      10 0X156   Site               0          19 0     
      # i 135 more rows

