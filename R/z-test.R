library(dplyr)
library(tidyr)
library(ggplot2)
library(mvtnorm)
theme_set(theme_light())
source("R/shared_variables.R", local = TRUE)
source("R/C-calibration/z-context.R", local = TRUE)

results <- readRDS("./rr.rds")

ggplot(results, aes(x = hiv.test.rate_3, y = cc.dx.W)) +
  geom_smooth() +
  geom_point(aes(col = factor(.iteration)))
