# rows with a denominator of 0 are removed

    Code
      row_removed
    Output
      # A tibble: 145 x 5
         GroupID GroupLevel Numerator Denominator Metric
         <chr>   <chr>          <int>       <dbl>  <dbl>
       1 0X101   Site              28         259 0.108 
       2 0X1020  Site               3          48 0.0625
       3 0X1043  Site              13         152 0.0855
       4 0X1048  Site               1          19 0.0526
       5 0X1053  Site               6          39 0.154 
       6 0X1068  Site               8          76 0.105 
       7 0X1084  Site               3          76 0.0395
       8 0X1128  Site               2          18 0.111 
       9 0X1183  Site               4          46 0.0870
      10 0X1257  Site              20         287 0.0697
      # i 135 more rows

