# =============================================================================
# c5_02_validate.R
# Question : Do the paired-effect estimators of C5-M2 recover known answers
#            with the actual designs: 32 points x 4 runs in both arms
#            (S1-S3), and 32 points x 4 runs against the cycle 4 baseline's
#            1-15 runs per point (S4)?
# Inputs   : cycle4/results/tables/c4_01_runs_per_point.csv
# Outputs  : cycle5/results/tables/c5_02_validation.csv
# Method   : c5_METHODS.md C5-M2; results/c5_02_validate.md
# =============================================================================

# Restart R before running this script (Ctrl_Shift_F10 / Cmd_Shift_0)

library(dplyr)
source("R/E-restart_assessment/cycle5/c5_config.R")
source("R/E-restart_assessment/cycle5/c5_utils.R")
set.seed(SEED)

n0_c4 <- read.csv("R/E-restart_assessment/cycle4/results/tables/c4_01_runs_per_point.csv")$n_runs
designs <- list(
  balanced = list(na = rep(N_PER_ARM, N_POINTS_C5), n0 = rep(N_PER_ARM, N_POINTS_C5)),
  s4_vs_c4 = list(na = rep(N_PER_ARM, N_POINTS_C5), n0 = n0_c4)
)

# Synthetic outcome in the units of the project outcome: equilibrium variance
# 1 split into sb2 = 0.25 between points and sw2 = 0.75 within (ICC 0.25,
# c4_04). The scenario multiplies the level by (1 - e) and adds a point-level
# deviation d_j of variance s2d, so that the true heterogeneity is
# e^2 (1 - e)^0 * sb2 ... = e^2 sb2 + s2d. Noise: normal, or skewed (centred
# gamma, shape 2) to mimic counts.
sim_one <- function(des, e, s2d, noise = "normal", mu = 20) {
  k <- N_POINTS_C5
  b <- rnorm(k, 0, sqrt(0.25))
  dj <- rnorm(k, 0, sqrt(s2d))
  w <- function(n) {
    if (noise == "normal") rnorm(n, 0, sqrt(0.75))
    else (rgamma(n, 2, 1) - 2) / sqrt(2) * sqrt(0.75)
  }
  g0 <- rep(seq_len(k), des$n0)
  ga <- rep(seq_len(k), des$na)
  y0 <- mu + b[g0] + w(length(g0))
  ya <- (1 - e) * (mu + b[ga]) + dj[ga] + w(length(ga))
  list(ya = ya, ga = ga, y0 = y0, g0 = g0,
    truth = c(delta = -e * mu, s2_delta = e^2 * 0.25 + s2d))
}

grid <- expand.grid(design = names(designs), e = c(0, 0.1), s2d = c(0, 0.02, 0.1, 0.3),
  noise = c("normal", "skewed"), stringsAsFactors = FALSE)
res <- bind_rows(parallel::mclapply(seq_len(nrow(grid)), mc.cores = N_CORES, function(i) {
  gr <- grid[i, ]
  set.seed(SEED + i)
  r <- t(vapply(seq_len(N_SYN_C5), function(b) {
    s <- sim_one(designs[[gr$design]], gr$e, gr$s2d, gr$noise)
    pe <- paired_effect(point_summary(s$ya, s$ga, s$y0, s$g0))
    c(delta = pe$delta, cov_delta = pe$delta_lo <= s$truth[["delta"]] &&
        s$truth[["delta"]] <= pe$delta_hi,
      s2 = pe$s2_delta, cov_s2 = pe$s2_lo <= s$truth[["s2_delta"]] &&
        s$truth[["s2_delta"]] <= pe$s2_hi,
      reject = pe$p_het < 0.05, truth_s2 = s$truth[["s2_delta"]],
      truth_delta = s$truth[["delta"]])
  }, numeric(7)))
  tibble(design = gr$design, e = gr$e, s2d = gr$s2d, noise = gr$noise,
    true_s2_delta = r[1, "truth_s2"],
    bias_delta = mean(r[, "delta"]) - r[1, "truth_delta"],
    se_bias_delta = sd(r[, "delta"]) / sqrt(nrow(r)),
    cover_delta = mean(r[, "cov_delta"]),
    mean_s2 = mean(r[, "s2"]), se_mean_s2 = sd(r[, "s2"]) / sqrt(nrow(r)),
    cover_s2 = mean(r[, "cov_s2"]), reject_rate = mean(r[, "reject"]))
}))

# Checks, as in earlier cycles: |z| < 3 for biases, stated ranges otherwise.
# 1000 replications give a Monte Carlo SD of 0.007 for a 95% coverage.
res <- res |> mutate(
  z_delta = bias_delta / se_bias_delta,
  z_s2 = (mean_s2 - true_s2_delta) / se_mean_s2,
  pass_delta = abs(z_delta) < 3 & cover_delta >= 0.93 & cover_delta <= 0.97,
  pass_s2 = abs(z_s2) < 3 & cover_s2 >= 0.93 & cover_s2 <= 0.97,
  pass_size = ifelse(true_s2_delta == 0, reject_rate >= 0.03 & reject_rate <= 0.07, NA)
)
write_tab(res, "c5_02_validation.csv")
print(as.data.frame(res |> select(design, e, s2d, noise, true_s2_delta, z_delta,
  cover_delta, z_s2, cover_s2, reject_rate, pass_delta, pass_s2, pass_size)))
cat("\nPassed: delta", sum(res$pass_delta), "/", nrow(res), "| s2_delta",
  sum(res$pass_s2), "/", nrow(res), "| size", sum(res$pass_size, na.rm = TRUE), "/",
  sum(!is.na(res$pass_size)), "\n")

save_session("c5_02")
