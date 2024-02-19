# Scratchpad for interactive testing before integration in a script

d_t <- readr::read_csv("./data/input/params.csv") |>
  select(param, value)
d_d <- readr::read_csv("../DoxyPEP/data/input/params.csv") |>
  select(param, value)


