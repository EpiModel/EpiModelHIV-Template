# Setup ------------------------------------------------------------------------
scenario_name <- "empty_scenario"
hpc_context <- TRUE

library(EpiModelHIV)
library(dplyr)
source("R/shared_variables.R", local = TRUE)
source("R/Z-calibration/z-context.R", local = TRUE)

# Process ----------------------------------------------------------------------
source("R/netsim_settings.R", local = TRUE)
targets <- EpiModelHIV::get_calibration_targets()

path_df <- fs::path(
  calib_dir,
  "merged_tibbles",
  paste0("df__", scenario_name, ".rds")
)

d_calibs <- readRDS(path_df) |>
  filter(time >= max(time) - year_steps) |>
  EpiModelHIV::mutate_calibration_targets() |>
  select(sim, any_of(names(targets))) |>
  summarise(across(everything(), mean), .by = "sim")

# Computes the precisions of each outcome:
# - detectable difference with power 90%
# - show these for each outcomes (appendix)
precisions <- vapply(
  names(d_calibs)[-1], # do not compute for `sim`
  \(var_name) {
    power.t.test(
      n = length(unique(d_calibs$sim)),
      sd = sd(d_calibs[[var_name]]),
      power = 0.9,
      type = "two.sample"
    )$delta
  },
  0
)
