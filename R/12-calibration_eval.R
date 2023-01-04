##
## 12. Epidemic Model Parameter Calibration, Local evaluation
##

# Setup ------------------------------------------------------------------------
source("R/utils-0_project_settings.R")

# Libraries --------------------------------------------------------------------
library("EpiModel")
library("dplyr")
library("tidyr")

d <- readRDS(paste0(calib_dir, "/assessments.rds"))

glimpse(d)

# Look at the median of the targets for every scenario
d %>%
  pivot_longer(-scenario_name) %>%
  separate(name, into = c("name", "quant"), sep = "__") %>%
  filter(quant == "q2") %>%
  pivot_wider(names_from = scenario_name, values_from = value)

# Look at q1, q2 and q3 for a specific scenario
d %>%
  filter(scenario_name == "1") %>%
  pivot_longer(-scenario_name) %>%
  separate(name, into = c("name", "quant"), sep = "__") %>%
  pivot_wider(names_from = quant, values_from = value)