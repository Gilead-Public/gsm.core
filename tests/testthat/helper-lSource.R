# Upstream null can arrive as NA or "", so tests treat both alike.
is_null_value <- function(x) is.na(x) | x == ""
