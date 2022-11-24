##
## 11. Epidemic Model Parameter Calibration, Local evaluation
##

# Setup ------------------------------------------------------------------------
library(EpiModel)
library(dplyr)
library(tidyr)
library(ggplot2)
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
  # filter(scenario_name == "empty_scenario") %>%
  pivot_longer(-scenario_name) %>%
  separate(name, into = c("name", "quant"), sep = "__") %>%
  pivot_wider(names_from = quant, values_from = value)

d2 <- readRDS("data/intermediate/calibration/assessments_raw.rds")

glimpse(d2)

ggplot(d2, aes(x = cc.dx.B)) +
  geom_density()

summary(d2$cc.dx.B)
