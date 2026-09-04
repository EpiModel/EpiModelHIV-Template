library(dplyr)
library(tidyr)
library(ggplot2)
library(mvtnorm)
theme_set(theme_light())
source("R/shared_variables.R", local = TRUE)
source("R/C-calibration/z-context.R", local = TRUE)

results <- readRDS("./gp_res.rds")
props <- readRDS("./props.rds")
results <- readRDS(fs::path(swfcalib_dir, "prev_results.rds"))
# ---- data ----
d <- tibble(
  p = results$syph.prob,
  y = results$ir100.syph
)

library(GauPro)

kern <- k_Matern52(D = 1)
kern <- k_Gaussian(D = 1)
gp <- gpkm(d$p, d$y, kernel = kern)

gp$plot1D()
gp$cool1Dplot()

summary(gp)
plot(gp)

# With mvtnorm
#
# - assumption about the structure of the kernel
# - does mvtnorm estimate the params? (of the kernel)
# - does mvtnorm estimate the measurement error?

rmvnorm(10, 1:5, diag(1, 5, 5))


# Use `hmer` for 3 GP, one per hiv.scale
