# rows with a denominator of 0 are removed

    Code
      row_removed
    Output
      # A tibble: 143 x 5
         GroupID GroupLevel Numerator Denominator Metric
         <chr>   <chr>          <int>       <dbl>  <dbl>
       1 0X071   Site               4          36 0.111 
       2 0X101   Site               7          78 0.0897
       3 0X1104  Site               5         119 0.0420
       4 0X1257  Site              22         209 0.105 
       5 0X1268  Site              10         149 0.0671
       6 0X1321  Site               5         146 0.0342
       7 0X1376  Site              22         277 0.0794
       8 0X1573  Site               1          35 0.0286
       9 0X1581  Site              11         106 0.104 
      10 0X1698  Site               5          50 0.1   
      # i 133 more rows

