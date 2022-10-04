##
## 11. Epidemic Model Parameter Calibration, Local evaluation
##

# Setup ------------------------------------------------------------------------
library("EpiModel")
library("dplyr")
library("tidyr")
source("R/00-project_settings.R")

d <- readRDS("data/intermediate/calibration/assessments.rds")

glimpse(d)

d %>%
  pivot_longer(-scenario_name) %>%
  separate(name, into = c("name", "quant"), sep = "__") %>%
  filter(quant == "q2") %>%
  pivot_wider(names_from = scenario_name, values_from = value)

# - target value

d %>%
  filter(scenario_name == "3") %>%
  pivot_longer(-scenario_name) %>%
  separate(name, into = c("name", "quant"), sep = "__") %>%
  pivot_wider(names_from = quant, values_from = value)

