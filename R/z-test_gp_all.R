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
if (!file.exists("data/run/gp_all_results2.Rds")) {
  n_cores <- 4
  source("./R/C-calibration/gp_process_calibs.R")
}
d <- readRDS("data/run/gp_all_results2.Rds")

# ------------------------------------------------------------------------------
# PrEP
# ------------------------------------------------------------------------------
par_name <- "prep.start.rate_1"
tar_name <- "cc.prep.B"

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

# ------------------------------------------------------------------------------
# cc.dx
# ------------------------------------------------------------------------------
par_names <- c("hiv.test.rate_1", "prep.start.rate_1")
par_raws <- d[par_names]
par_ranges <- lapply(par_raws, range)
tar_name <- "cc.dx.B"
tar <- targets[tar_name]
val <- d[[tar_name]]
prep_spar <- 0.06662719

X <- mapply(mscale, par_raws, par_ranges)

mod <- mleHetGP(X, val, covtype = "Matern5_2", eps = 1e-6)

X_pred <- matrix(c(seq(0, 1, length.out = 100), rep(prep_spar, 100)), ncol = ncol(X))
p_mod <- predict(x = X_pred, object = mod)

d_pred <- tibble(
  x = munscale(X_pred[, 1], par_ranges[[1]]),
  y = p_mod$mean,
  y_min = y - 1.96 * sqrt(p_mod$sd2),
  y_max = y + 1.96 * sqrt(p_mod$sd2)
)
d_vals <- tibble(x = par_raws[[1]], y = val)

ggplot(d_pred, aes(x = x)) +
  geom_line(aes(y = y)) +
  geom_ribbon(aes(ymin = y_min, ymax = y_max), alpha = 0.1) +
  geom_hline(yintercept = tar)

f_mean <- function(x) {
  X_pred <- matrix(c(x, prep_spar), ncol = ncol(X))
  predict(x = X_pred, object = mod)$mean - tar
}
# search over the scaled domain; assumes a single crossing (fine for monotone)
root <- uniroot(f_mean, interval = c(0, 1))
par_star <- munscale(root$root, par_ranges[[1]])
par_star

# ------------------------------------------------------------------------------
# cc.vsupp
# ------------------------------------------------------------------------------
par_names <- c("tx.halt.rate_1", "hiv.test.rate_1", "prep.start.rate_1")
par_raws <- d[par_names]
par_ranges <- lapply(par_raws, range)
tar_name <- "cc.vsupp.B"
tar <- targets[tar_name]
val <- d[[tar_name]]
dx_spar <- 0.3374811

X <- mapply(mscale, par_raws, par_ranges)

mod <- mleHetGP(X, val, covtype = "Matern5_2", eps = 1e-6)

X_pred <- matrix(
  c(
    seq(0, 1, length.out = 100),
    rep(dx_spar, 100),
    rep(prep_spar, 100)
  ),
  ncol = ncol(X)
)
p_mod <- predict(x = X_pred, object = mod)

d_pred <- tibble(
  x = munscale(X_pred[, 1], par_ranges[[1]]),
  y = p_mod$mean,
  y_min = y - 1.96 * sqrt(p_mod$sd2),
  y_max = y + 1.96 * sqrt(p_mod$sd2)
)
d_vals <- tibble(x = par_raws[[1]], y = val)

ggplot(d_pred, aes(x = x)) +
  geom_line(aes(y = y)) +
  geom_ribbon(aes(ymin = y_min, ymax = y_max), alpha = 0.1) +
  geom_hline(yintercept = tar)

f_mean <- function(x) {
  X_pred <- matrix(c(x, dx_spar, prep_spar), ncol = ncol(X))
  predict(x = X_pred, object = mod)$mean - tar
}
# search over the scaled domain; assumes a single crossing (fine for monotone)
root <- uniroot(f_mean, interval = c(0, 1))
par_star <- munscale(root$root, par_ranges[[1]])
par_star

# ------------------------------------------------------------------------------
# syph
# ------------------------------------------------------------------------------
par_names <- c("syph.prob", "tx.halt.rate_1", "hiv.test.rate_1", "prep.start.rate_1")
par_raws <- d[par_names]
par_ranges <- lapply(par_raws, range)
tar_name <- "ir100.syph"
tar <- targets[tar_name]
val <- d[[tar_name]]
halt_spar <- 0.6711258

X <- mapply(mscale, par_raws, par_ranges)

mod <- mleHetGP(X, val, covtype = "Matern5_2", eps = 1e-6)

X_pred <- matrix(
  c(
    seq(0, 1, length.out = 100),
    rep(halt_spar, 100),
    rep(dx_spar, 100),
    rep(prep_spar, 100)
  ),
  ncol = ncol(X)
)
p_mod <- predict(x = X_pred, object = mod)

d_pred <- tibble(
  x = munscale(X_pred[, 1], par_ranges[[1]]),
  y = p_mod$mean,
  y_min = y - 1.96 * sqrt(p_mod$sd2),
  y_max = y + 1.96 * sqrt(p_mod$sd2)
)
d_vals <- tibble(x = par_raws[[1]], y = val)

ggplot(d_pred, aes(x = x)) +
  geom_line(aes(y = y)) +
  geom_ribbon(aes(ymin = y_min, ymax = y_max), alpha = 0.1) +
  geom_hline(yintercept = tar)

f_mean <- function(x) {
  X_pred <- matrix(c(x, halt_spar, dx_spar, prep_spar), ncol = ncol(X))
  predict(x = X_pred, object = mod)$mean - tar
}
# search over the scaled domain; assumes a single crossing (fine for monotone)
root <- uniroot(f_mean, interval = c(0, 1))
par_star <- munscale(root$root, par_ranges[[1]])
par_star

# ------------------------------------------------------------------------------
# gono
# ------------------------------------------------------------------------------
par_names <- c("gono.uret.prob", "tx.halt.rate_1", "hiv.test.rate_1", "prep.start.rate_1")
par_raws <- d[par_names]
par_ranges <- lapply(par_raws, range)
tar_name <- "ir100.gono"
tar <- targets[tar_name]
val <- d[[tar_name]]

X <- mapply(mscale, par_raws, par_ranges)

mod <- mleHetGP(X, val, covtype = "Matern5_2", eps = 1e-6)

X_pred <- matrix(
  c(
    seq(0, 1, length.out = 100),
    rep(halt_spar, 100),
    rep(dx_spar, 100),
    rep(prep_spar, 100)
  ),
  ncol = ncol(X)
)
p_mod <- predict(x = X_pred, object = mod)

d_pred <- tibble(
  x = munscale(X_pred[, 1], par_ranges[[1]]),
  y = p_mod$mean,
  y_min = y - 1.96 * sqrt(p_mod$sd2),
  y_max = y + 1.96 * sqrt(p_mod$sd2)
)
d_vals <- tibble(x = par_raws[[1]], y = val)

ggplot(d_pred, aes(x = x)) +
  geom_line(aes(y = y)) +
  geom_ribbon(aes(ymin = y_min, ymax = y_max), alpha = 0.1) +
  geom_hline(yintercept = tar)

f_mean <- function(x) {
  X_pred <- matrix(c(x, halt_spar, dx_spar, prep_spar), ncol = ncol(X))
  predict(x = X_pred, object = mod)$mean - tar
}
# search over the scaled domain; assumes a single crossing (fine for monotone)
root <- uniroot(f_mean, interval = c(0, 1))
par_star <- munscale(root$root, par_ranges[[1]])
par_star

# ------------------------------------------------------------------------------
# chla
# ------------------------------------------------------------------------------
par_names <- c("chla.uret.prob", "tx.halt.rate_1", "hiv.test.rate_1", "prep.start.rate_1")
par_raws <- d[par_names]
par_ranges <- lapply(par_raws, range)
tar_name <- "ir100.chla"
tar <- targets[tar_name]
val <- d[[tar_name]]

X <- mapply(mscale, par_raws, par_ranges)

mod <- mleHetGP(X, val, covtype = "Matern5_2", eps = 1e-6)

X_pred <- matrix(
  c(
    seq(0, 1, length.out = 100),
    rep(halt_spar, 100),
    rep(dx_spar, 100),
    rep(prep_spar, 100)
  ),
  ncol = ncol(X)
)
p_mod <- predict(x = X_pred, object = mod)

d_pred <- tibble(
  x = munscale(X_pred[, 1], par_ranges[[1]]),
  y = p_mod$mean,
  y_min = y - 1.96 * sqrt(p_mod$sd2),
  y_max = y + 1.96 * sqrt(p_mod$sd2)
)
d_vals <- tibble(x = par_raws[[1]], y = val)

ggplot(d_pred, aes(x = x)) +
  geom_line(aes(y = y)) +
  geom_ribbon(aes(ymin = y_min, ymax = y_max), alpha = 0.1) +
  geom_hline(yintercept = tar)

f_mean <- function(x) {
  X_pred <- matrix(c(x, halt_spar, dx_spar, prep_spar), ncol = ncol(X))
  predict(x = X_pred, object = mod)$mean - tar
}
# search over the scaled domain; assumes a single crossing (fine for monotone)
root <- uniroot(f_mean, interval = c(0, 1))
par_star <- munscale(root$root, par_ranges[[1]])
par_star
