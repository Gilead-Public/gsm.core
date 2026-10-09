# rows with a denominator of 0 are removed

    Code
      row_removed
    Output
      # A tibble: 143 x 5
         GroupID GroupLevel Numerator Denominator Metric
         <chr>   <chr>          <int>       <dbl>  <dbl>
       1 0X027   Site              11          98 0.112 
       2 0X101   Site              31         300 0.103 
       3 0X1010  Site               1          14 0.0714
       4 0X1099  Site               2           2 1     
       5 0X1231  Site              11          60 0.183 
       6 0X1257  Site              18         300 0.06  
       7 0X1400  Site              19         298 0.0638
       8 0X162   Site               3          62 0.0484
       9 0X165   Site               3          36 0.0833
      10 0X1726  Site               1          10 0.1   
      # i 133 more rows

