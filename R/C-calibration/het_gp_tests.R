library(hetGP)
library(MASS)
library(dplyr)
library(ggplot2)
theme_set(theme_light())
mscale <- function(x, rnge) (x - rnge[1]) / diff(rnge)
munscale <- function(x, rnge) x * diff(rnge) + rnge[1]
d <- readRDS("./sti_results_rep2.rds")
disease <- c("syph", "gono", "chla")[3]
mod_choice <- c("hom", "het")[2]

# Choice of inputs -------------------------------------------------------------
if (disease == "syph") {
  par_raw <- d$syph.prob
  val <- d$ir100.syph
  tar <- 2
} else if (disease == "gono") {
  par_raw <- d$gono.uret.prob
  val <- d$ir100.gono
  tar <- 12.810
} else if (disease == "chla") {
  par_raw <- d$chla.uret.prob
  val <- d$ir100.chla
  tar <- 14.59
}
par_range <- c(0.05, 0.3)

# Models -----------------------------------------------------------------------
par <- mscale(par_raw, par_range)
covtype <- "Matern5_2"
if (mod_choice == "hom") {
  mod <- mleHomGP(par, val, covtype = covtype)
} else if (mod_choice == "het") {
  mod <- mleHetGP(par, val, covtype = covtype, eps = 1e-6)
}

# Plotting ---------------------------------------------------------------------
d_pred <- tibble(x = seq(0, 1, length.out = 100))
p_mod <- predict(x = matrix(d_pred$x, ncol = 1), object = mod)

d_pred <- d_pred |>
  mutate(
    x = munscale(x, par_range),
    y = p_mod$mean,
    y_min = y - 1.96 * sqrt(p_mod$sd2),
    y_max = y + 1.96 * sqrt(p_mod$sd2)
  )
d_vals <- tibble(x = munscale(par, par_range), y = val)

ggplot(d_pred, aes(x = x)) +
  geom_line(aes(y = y)) +
  geom_ribbon(aes(ymin = y_min, ymax = y_max), alpha = 0.1) +
  geom_point(data = d_vals, aes(x = x, y = y), alpha = 0.5) +
  geom_hline(yintercept = tar)

# Make a batch with crit_cSUR --------------------------------------------------

n_batch <- length(par_raw)
new_p <- numeric(n_batch)
for (i in seq_len(n_batch)) {
  opt <- crit_optim(mod, crit = "crit_cSUR", thres = tar, h = 0,
                    control = list(multi.start = 10, maxit = 100))
  new_p[i] <- opt$par
  xn <- matrix(opt$par, nrow = 1)
  mod <- update(mod, Xnew = xn, Znew = predict(mod, xn)$mean, maxit = 0)
}
np <- munscale(new_p, par_range)
sort(np)
saveRDS(np, paste0(disease, "-props.rds"))




# # Make a batch by estimating the probable region where `tar` lies --------------
#
# # TODO: understand this function precisely
# contour_ci <- function(model, thres, grid01, n_sim = 500,
#                        probs = c(0.05, 0.95)) {
#   G <- matrix(grid01, ncol = 1)
#   p <- predict(model, G, xprime = G)          # xprime -> full covariance
#   Sig <- p$cov + diag(model$eps, length(grid01))
#   paths <- MASS::mvrnorm(n_sim, mu = p$mean, Sigma = Sig)
#
#   cross <- apply(paths, 1, function(f) {
#     i <- which(diff(sign(f - thres)) != 0)
#     if (!length(i)) return(NA_real_)
#     i <- i[1]                                  # first crossing only
#     grid01[i] + (thres - f[i]) / (f[i + 1] - f[i]) *
#       (grid01[i + 1] - grid01[i])
#   })
#
#   c(quantile(cross, probs, na.rm = TRUE),
#     frac_crossing = mean(!is.na(cross)))
# }
#
# # TODO: understand this part
# #   - what is generic and which are "random number"
# grid01 <- seq(0, 1, length.out = 501)
# ci <- contour_ci(het, thres = tar, grid01, n_sim = 1000)
# ci   # 5%, 95%, frac_crossing
#
# # NOTE: why is this part here, what is the purpose
# # design: unique locations across the plausible crossing region
# w  <- diff(ci[1:2])
# lo <- max(0, ci[1] - 0.3 * w)
# hi <- min(1, ci[2] + 0.3 * w)
#
# # NOTE: magic numbers I guess?
# n_uniq <- 16
# n_rep  <- 3
# locs <- seq(lo, hi, length.out = n_uniq)
#
# # replicate counts scaled by local noise — more reps where it's noisy
# nug <- predict(het, matrix(locs, ncol = 1))$nugs
# reps <- pmax(1, round(n_rep * nug / mean(nug)))
# reps <- reps * 48 %/% sum(reps)          # rescale to ~48 of the budget
#
# picks <- rep(locs, times = reps)
# picks <- c(picks, seq(0, 1, length.out = 64 - length(picks)))  # insurance
# new_p <- munscale(picks, par_range)
# sort(new_p)
