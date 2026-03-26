# rows with a denominator of 0 are removed

    Code
      row_removed
    Output
      # A tibble: 147 x 5
         GroupID GroupLevel Numerator Denominator Metric
         <chr>   <chr>          <int>       <dbl>  <dbl>
       1 0X022   Site               4          49 0.0816
       2 0X101   Site               7          89 0.0787
       3 0X1102  Site               9         111 0.0811
       4 0X1233  Site              14         106 0.132 
       5 0X1257  Site              16         214 0.0748
       6 0X1273  Site               0          21 0     
       7 0X1544  Site               1          79 0.0127
       8 0X1727  Site              13         167 0.0778
       9 0X1748  Site              26         125 0.208 
      10 0X1750  Site              19         277 0.0686
      # i 137 more rows

