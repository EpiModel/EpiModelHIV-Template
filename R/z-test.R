# Scratchpad for interactive testing before integration in a script
library(dplyr)
d_t <- readr::read_csv("./data/input/params.csv") |>
  select(param, value)
d_d <- readr::read_csv("../DoxyPEP/data/input/params.csv") |>
  select(param, value)

d_all <- full_join(d_t, d_d, by = "param")

d_all |>
  filter(value.x != value.y) |>
  print(n = 100)
