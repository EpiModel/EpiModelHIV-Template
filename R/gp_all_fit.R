library(dplyr)
library(tidyr)
library(ggplot2)
library(mvtnorm)
library(hetGP)
source("R/shared_variables.R", local = TRUE)
source("R/C-calibration/z-context.R", local = TRUE)
source("./R/C-calibration/z-gp_utils.R", local = TRUE)
targets <- EpiModelHIV::get_calibration_targets()

# process_calibs ---------------------------------------------------------------
# if (!file.exists("data/run/gp_all_results2.Rds")) {
#   n_cores <- 4
#   source("./R/C-calibration/gp_process_calibs.R")
# }
d <- readRDS("data/run/gp_all_results2.Rds")

par_star <- c(
  prep.start.rate_1     = NA,
  prep.start.rate_2     = NA,
  prep.start.rate_3     = NA,
  hiv.test.rate_1       = NA,
  hiv.test.rate_2       = NA,
  hiv.test.rate_3       = NA,
  tx.halt.rate_1        = NA,
  tx.halt.rate_2        = NA,
  tx.halt.rate_3        = NA,
  hiv.trans.scale_1     = NA,
  hiv.trans.scale_2     = NA,
  hiv.trans.scale_3     = NA,
  gono.uret.prob        = NA,
  chla.uret.prob        = NA,
  syph.prob             = NA,
  aids.off.tx.mort.rate = NA,
  a.rate                = NA
)

par_star_raw <- c(
  prep.start.rate_1     = NA,
  prep.start.rate_2     = NA,
  prep.start.rate_3     = NA,
  hiv.test.rate_1       = NA,
  hiv.test.rate_2       = NA,
  hiv.test.rate_3       = NA,
  tx.halt.rate_1        = NA,
  tx.halt.rate_2        = NA,
  tx.halt.rate_3        = NA,
  hiv.trans.scale_1     = NA,
  hiv.trans.scale_2     = NA,
  hiv.trans.scale_3     = NA,
  gono.uret.prob        = NA,
  chla.uret.prob        = NA,
  syph.prob             = NA,
  aids.off.tx.mort.rate = NA,
  a.rate                = NA
)

ethn <- c("B", "H", "W")
fit_params <- function() {
  par_raws <- d[par_names]
  par_ranges <- lapply(par_raws, range)
  tar <- targets[tar_name]
  val <- d[[tar_name]]
  X <- mapply(mscale, par_raws, par_ranges)
  # mod <- mleHetGP(X, val, covtype = "Matern5_2", eps = 1e-6)
  mod <- mleHomGP(X, val, covtype = "Matern5_2", eps = 1e-6)
  f_mean <- function(x) {
    X_pred <- matrix(c(x, par_star_raw[par_names[-1]]), ncol = ncol(X))
    predict(x = X_pred, object = mod)$mean - tar
  }
  root <- uniroot(f_mean, interval = c(0, 1))
  par_star_raw[par_names[1]] <<- root$root
  par_star[par_names[1]] <<- munscale(root$root, par_ranges[[1]])
}

# ------------------------------------------------------------------------------
# PrEP
# ------------------------------------------------------------------------------
for (i in seq_along(ethn)) {
  par_names <- paste0("prep.start.rate_", i)
  tar_name <- paste0("cc.prep.", ethn[i])
  fit_params()
}

# ------------------------------------------------------------------------------
# cc.dx
# ------------------------------------------------------------------------------
for (i in seq_along(ethn)) {
  par_names <- c(
    paste0("hiv.test.rate_", i),
    paste0("prep.start.rate_", i)
  )
  tar_name <- paste0("cc.dx.", ethn[i])
  fit_params()
}

# ------------------------------------------------------------------------------
# cc.vsupp
# ------------------------------------------------------------------------------
for (i in seq_along(ethn)) {
  par_names <- c(
    paste0("tx.halt.rate_", i),
    paste0("hiv.test.rate_", i),
    paste0("prep.start.rate_", i)
  )
  tar_name <- paste0("cc.vsupp.", ethn[i])
  fit_params()
}


# ------------------------------------------------------------------------------
# syph
# ------------------------------------------------------------------------------
par_names <- c(
  "syph.prob",
  paste0("hiv.test.rate_", 1)
)
tar_name <- "ir100.syph"
fit_params()

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
