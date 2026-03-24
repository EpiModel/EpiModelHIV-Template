## 4. Epidemic Model Scenarios Assessment
##
## Interactively explore the output of the simulation. Works with both local
## and HPC results (change `hpc_context` and download the merged_tibbles/ from
## the HPC first).
##
## Change the scenario name below to inspect different scenarios.

# Restart R before running this script (Ctrl_Shift_F10 / Cmd_Shift_0)

# Setup ------------------------------------------------------------------------
library(EpiModelHIV)
library(dplyr)

source("R/shared_variables.R", local = TRUE)
source("R/B-model_dev/z-context.R", local = TRUE)

# Process ----------------------------------------------------------------------

# Load the results of a single scenario
d_sim <- readRDS(fs::path(scenarios_dir, "merged_tibbles", "df__scenario_1.rds"))

glimpse(d_sim)
head(d_sim)

d_sim <- d_sim |>
  mutate_calibration_targets() |>
  as.epi.data.frame() # ensure the data.frame can be used with `plot`

plot(
  d_sim,
  y = paste0("cc.dx.", c("B", "H", "W")),
  main = "Proportion of Diagnosed (Black)"
)
