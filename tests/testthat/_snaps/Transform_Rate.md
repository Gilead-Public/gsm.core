# rows with a denominator of 0 are removed

    Code
      row_removed
    Output
      # A tibble: 144 x 5
         GroupID GroupLevel Numerator Denominator Metric
         <chr>   <chr>          <int>       <dbl>  <dbl>
       1 0X004   Site               3          35 0.0857
       2 0X101   Site              25         183 0.137 
       3 0X1257  Site              16         200 0.08  
       4 0X1268  Site               5          63 0.0794
       5 0X1321  Site              12         120 0.1   
       6 0X1750  Site              13         267 0.0487
       7 0X1759  Site               6          33 0.182 
       8 0X180   Site              28         246 0.114 
       9 0X1856  Site               5         101 0.0495
      10 0X187   Site               8         151 0.0530
      # i 134 more rows

