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

# process_calibs ---------------------------------------------------------------
n_cores <- 4
source("./R/C-calibration/gp_process_calibs.R")
d <- readRDS("data/run/gp_lhs_scale.Rds")

# i.prev.dx.B  -----------------------------------------------------------------
par_name <- c("hiv.trans.scale_1")
tar_name <- "i.prev.dx.B"

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


# i.prev.dx.H ------------------------------------------------------------------
par_name <- c("hiv.trans.scale_2")
tar_name <- "i.prev.dx.H"

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

# i.prev.dx.W ------------------------------------------------------------------
par_name <- c("hiv.trans.scale_3")
tar_name <- "i.prev.dx.W"

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


# 3 x 3 ------------------------------------------------------------------------
par_names <- paste0("hiv.trans.scale_", 1:3)
par_raws <- d[par_names]
par_ranges <- lapply(par_raws, range)
tar_names <- paste0("i.prev.dx.", c("B", "H", "W"))
tars <- targets[tar_names]

X <- mapply(mscale, par_raws, par_ranges)

mods <- lapply(tar_names, \(tar_name) {
  val <- d[[tar_name]]
  mleHetGP(X, val, covtype = "Matern5_2", eps = 1e-6)
})
names(mods) <- tar_names

resid <- function(u) {
  xm <- matrix(pmin(pmax(u, 0), 1), nrow = 1)
  sapply(seq_along(mods), function(k) predict(mods[[k]], xm)$mean - tars[k])
}

fit <- minpack.lm::nls.lm(
  par = rep(0.5, 3),
  fn = resid,
  lower = rep(0, 3),
  upper = rep(1, 3)
)
par_star <- setNames(mapply(munscale, fit$par, par_ranges), par_names)
par_star
