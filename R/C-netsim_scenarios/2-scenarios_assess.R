## 2. Epidemic Model Scenarios Assessment
##
## Interactively explore the output of the simulation. Be it local or HPC
## simulations made by the workflow

# Restart R before running this script (Ctrl_Shift_F10 / Cmd_Shift_0)

# Setup ------------------------------------------------------------------------
library(EpiModelHIV)
library(dplyr)

source("R/shared_variables.R", local = TRUE)
source("R/C-netsim_scenarios/z-context.R", local = TRUE)

# Process ----------------------------------------------------------------------

d_sim <- readRDS(fs::path(scenarios_dir, "merged_tibbles", "df__scenario_1.rds"))

glimpse(d_sim)
head(d_sim)
