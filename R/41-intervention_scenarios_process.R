##
## 11. Epidemic Model Parameter Calibration, Processing of the simulation files
##

# Setup ------------------------------------------------------------------------
source("R/utils-0_project_settings.R")
source("R/utils-scenarios_outcomes.R")

batches_infos <- EpiModelHPC::get_scenarios_batches_infos(
  "data/intermediate/scenarios"
)

# process each batch
outcomes_raw <- lapply(
  seq_len(nrow(batches_infos)),
  function(i) process_one_scenario_batch(batches_infos[i, ])
)

# bind all rows into 1 data frame with 1 row per unique simulation
outcomes_raw <- bind_rows(outcomes_raw)
head(outcomes_raw)
saveRDS(outcomes_raw, "data/intermediate/scenarios/outcomes_raw.rds")

# summarise the results into a data frame with one row per scenario
#   here we present each outcome with q1, median, q3
outcomes <- outcomes_raw %>%
  select(- c(sim, batch_number)) %>%
  group_by(scenario_name) %>%
  summarise(across(
    everything(),
    list(
      q1 = ~ quantile(.x, 0.25, na.rm = TRUE),
      q2 = ~ quantile(.x, 0.50, na.rm = TRUE),
      q3 = ~ quantile(.x, 0.75, na.rm = TRUE)
    ),
    .names = "{.col}__{.fn}"
  ))

head(outcomes)

# Save the result --------------------------------------------------------------
saveRDS(outcomes, "data/intermediate/scenarios/outcomes.rds")
readr::write_csv(outcomes, "data/intermediate/scenarios/outcomes.csv")


