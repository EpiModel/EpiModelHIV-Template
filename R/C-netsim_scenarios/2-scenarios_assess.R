## 2. Epidemic Model Scenarios Assessment
##
## Interactively explore the output of the simulation. Be it local or HPC
## simulations made by the workflow

# This script should be run in a fresh R session

# Setup ------------------------------------------------------------------------
library(EpiModelHIV)
library(dplyr)

source("R/shared_variables.R", local = TRUE)
source("R/C-netsim_scenarios/z-context.R", local = TRUE)

# Process ----------------------------------------------------------------------

d_sim <- readRDS(fs::path(scenarios_dir, "merged_tibbles", "df__scenario_1.rds"))

glimpse(d_sim)
head(d_sim)
