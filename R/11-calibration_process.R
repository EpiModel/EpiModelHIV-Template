##
## 11. Epidemic Model Parameter Calibration, Processing of the simulation files
##

# Setup ------------------------------------------------------------------------
source("R/00-project_settings.R")
source("R/utils-targets.R")
library(dplyr)

batches_infos <- EpiModelHPC::get_scenarios_batches_infos(calibration_dir)

process_one_batch <- function(scenario_infos) {
  sim <- readRDS(scenario_infos$file_name)

  d_sim <- as_tibble(sim)

  d_sim <- mutate_calibration_targets(d_sim) # from "R/utils-targets.R"

  d_sim <- d_sim %>%
    filter(time >= max(time) - 52) %>%
    select(sim, all_of(names(targets))) %>%
    group_by(sim) %>%
    summarise(across(
      everything(),
      ~ mean(.x, na.rm = TRUE)
    )) %>%
    ungroup()

  d_sim <- mutate(d_sim,
      scenario_name = scenario_infos$scenario_name,
      batch_number = scenario_infos$batch_number
    )

  select(d_sim, scenario_name, batch_number, sim, everything())
}

assessments_raw <- lapply(
  seq_len(nrow(batches_infos)),
  function(i) process_one_batch(batches_infos[i, ])
)

assessments_raw <- bind_rows(assessments_raw)
saveRDS(assessments_raw, paste0(calibration_dir, "/assessments_raw.rds"))

assessments <- assessments_raw %>%
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

# Save the result --------------------------------------------------------------
saveRDS(assessments, paste0(calibration_dir, "/assessments.rds"))
