library(dplyr)
library(tidyr)
library(ggplot2)
library(mvtnorm)
theme_set(theme_light())
source("R/shared_variables.R", local = TRUE)
source("R/C-calibration/z-context.R", local = TRUE)

results_raws <- readRDS("./rr.rds")
results <- filter(results_raws, .wave == 5)

ggplot(results, aes(x = syph.prob, y = ir100.syph)) +
  geom_smooth() +
  geom_point(aes(col = factor(.wave)))
