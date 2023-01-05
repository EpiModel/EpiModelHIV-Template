##
## 11. Epidemic Model Parameter Calibration, Processing of the simulation files
##

# Libraries --------------------------------------------------------------------
library("dplyr")
library("future.apply")

# Settings ---------------------------------------------------------------------
source("./R/utils-0_project_settings.R")
context <- if (!exists("context")) "local" else "hpc"

if (context == "local") {
  plan(sequential)
} else if (context == "hpc") {
  plan(multisession, workers = ncores)
} else  {
  stop("The `context` variable must be set to either 'local' or 'hpc'")
}

# ------------------------------------------------------------------------------
source("./R/utils-targets.R")
batches_infos <- EpiModelHPC::get_scenarios_batches_infos(calib_dir)

process_one_batch <- function(scenario_infos) {
  d_sim <- readRDS(scenario_infos$file_name) %>% as_tibble()

  d_sim <- d_sim %>%
    mutate_calibration_targets() %>% # from "R/utils-targets.R"
    filter(time >= max(time) - 52) %>%
    select(sim, any_of(names(targets))) %>%
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

assessments_raw <- future_lapply(
  seq_len(nrow(batches_infos)),
  function(i) process_one_batch(batches_infos[i, ])
)

assessments_raw <- bind_rows(assessments_raw)
saveRDS(assessments_raw, "./data/intermediate/calibration/assessments_raw.rds")

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
saveRDS(assessments, "./data/intermediate/calibration/assessments.rds")
