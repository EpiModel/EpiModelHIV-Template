# Libraries --------------------------------------------------------------------
library(dplyr)

# Settings ---------------------------------------------------------------------
source("./R/shared_variables.R", local = TRUE)
source("./R/F-intervention_scenarios/outcomes.R", local = TRUE)

scenarios_tibble_dir <- fs::path(scenarios_dir, "merged_tibbles")
scenarios_info <- EpiModelHPC::get_scenarios_tibble_infos(scenarios_tibble_dir)

d_ref <- make_d_ref(fs::path(scenarios_tibble_dir, "df__test_1_treat_1.rds"))

d_ls <- future.apply::future_lapply(
  seq_len(nrow(scenarios_info)),
  \(i) process_one_scenario(scenarios_info[i, ], d_ref)
)

d_sc_raw <- dplyr::bind_rows(d_ls)
glimpse(d_sc_raw)


source("./R/F-intervention_scenarios/labels.R", local = TRUE)

format_table(d_sc_raw, var_labels, format_patterns) |>
  readr::write_csv("data/output/table.csv")
