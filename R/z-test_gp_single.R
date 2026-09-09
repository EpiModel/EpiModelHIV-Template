library(dplyr)
library(tidyr)
library(ggplot2)
library(mvtnorm)
library(hetGP)
theme_set(theme_light())
source("R/shared_variables.R", local = TRUE)
source("R/C-calibration/z-context.R", local = TRUE)
source("./R/C-calibration/z-gp_utils.R", local = TRUE)
targets <- EpiModelHIV::get_calibration_targets()

results <- readRDS("./sw_res.rds")
d <- readRDS("./res4.rds")

d <- filter(results, .wave == 3)
par_name <- "syph.prob"
tar_name <- "ir100.syph"

par_raw <- d[[par_name]]
par_range <- range(par_raw)
tar <- targets[tar_name]
val <- d[[tar_name]]

plot_par_tar(d, par_name, tar_name, tar)

par <- mscale(par_raw, par_range)
mod <- mleHetGP(par, val, covtype = "Matern5_2", eps = 1e-6)

f_mean <- function(x) predict(mod, matrix(x, ncol = 1))$mean - tar
# search over the scaled domain; assumes a single crossing (fine for monotone)
root <- uniroot(f_mean, interval = c(0, 1))
par_star_raw <- root$root
par_star <- munscale(root$root, par_range)
par_star

# Plotting
plot_gp(mod, val, par_range, tar)
