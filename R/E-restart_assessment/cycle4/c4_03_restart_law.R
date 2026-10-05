# =============================================================================
# c4_03_restart_law.R
# Question : Is a same-parameter restart seamless? Do the runs restarted from
#            the 32 saved states continue as their source chains would have
#            (weekly continuity, one-year changes), and do they settle into
#            the stationary law of the cold-start runs (and not that of the
#            x0 runs)?
# Inputs   : data/run/restart_assessment/cycle4/c4_01_annual_pool.rds,
#            data/run/restart_assessment/cycle3/c3_01_annual_cold.rds,
#            data/run/restart_assessment/01_annual.rds (cycle 1)
# Outputs  : cycle4/results/tables/c4_03_*.csv, figures/c4_03_*.png
# Method   : c4_METHODS.md C4-M3; c3_METHODS.md C3-M2;
#            results/c4_03_restart_law.md
# =============================================================================

# Restart R before running this script (Ctrl_Shift_F10 / Cmd_Shift_0)

library(dplyr)
library(ggplot2)
theme_set(theme_light())
source("R/E-restart_assessment/cycle4/c4_config.R")
source("R/E-restart_assessment/cycle4/c4_utils.R")
set.seed(SEED)

pool <- readRDS(POOL_ANNUAL_PATH)
cold <- readRDS(COLD_ANNUAL_PATH)
dict <- pool$dict
key <- dict$name[dict$block == "key"]
state <- dict$name[dict$block == "state"]
proj <- dict$name[dict$block == "project" & !grepl("^cml_incid", dict$name)]
g <- pool$point
nj <- pool$n_per_point
src <- pool$source_sim
n_p <- length(g)

# (a) Weekly continuity across the restart (C4-M3) --------------------------------
# Cross-run means of the pool runs at weeks 0 ... 104 after the restart, and
# of their source chains at weeks -104 ... 0, weighting each source chain by
# its number of runs so that both sides average over the same states (they
# coincide at week 0 by construction). For stocks, the first increment after
# the restart (week 0 -> 1) is compared with the increments of the other
# weeks; for flows, the week-1 level with the levels of the other weeks.
# z = (first - median) / MAD, as cycle 2 (C2-M0). A slower artifact would
# show as a level shift between the two sides: the mean of weeks 1-52 after
# minus the mean of weeks -51 ... 0 before, in SD_pi units of the annual
# value (`level_shift_sd`).
raw_vars <- names(pool$kind)
w_src <- pool$seam_src |>
  mutate(wt = nj[point]) |>
  summarise(across(all_of(raw_vars), ~ sum(.x * wt) / sum(wt)), .by = week)
w_pool <- pool$seam_pool |>
  summarise(across(all_of(raw_vars), mean), .by = week)
seam <- bind_rows(w_src |> filter(week < 0), w_pool) |> arrange(week)
cont <- bind_rows(lapply(raw_vars, function(v) {
  y <- seam[[v]]
  wk <- seam$week
  if (pool$kind[[v]] == "stock") {
    inc <- diff(y)
    inc_wk <- wk[-1] # increment ending at week w
    first <- inc[inc_wk == 1]
    ref <- inc[inc_wk != 1]
  } else {
    first <- y[wk == 1]
    ref <- y[wk != 1 & wk != 0]
  }
  s <- mad(ref)
  sd_pi <- sqrt(pi_moments(cold$Y[[v]], LATE_START:N_YEARS)$s2) /
    if (pool$kind[[v]] == "flow") year_steps else 1
  tibble(var = v, kind = pool$kind[[v]], first = first,
    ref_median = median(ref), ref_mad = s,
    z = if (s > 0) (first - median(ref)) / s else NA_real_,
    level_shift_sd = (mean(y[wk >= 1 & wk <= 52]) -
      mean(y[wk >= -51 & wk <= 0])) / sd_pi)
})) |>
  arrange(desc(abs(z)))
write_tab(cont, "c4_03_weekly_continuity.csv")
print(as.data.frame(head(cont, 12)))

# Empirical null for the weekly test: the same z, computed for every other
# week w (increment or level at w against all weeks except w and 1), and
# the maximum |z| over variables per week. The restart week is unremarkable
# if many ordinary weeks reach the same maximum.
wk_all <- seam$week
z_week <- function(v, w) {
  y <- seam[[v]]
  if (pool$kind[[v]] == "stock") {
    inc <- diff(y)
    iw <- wk_all[-1]
    ref <- inc[!(iw %in% c(1, w))]
    (inc[iw == w] - median(ref)) / mad(ref)
  } else {
    ref <- y[!(wk_all %in% c(0, 1, w))]
    (y[wk_all == w] - median(ref)) / mad(ref)
  }
}
other_weeks <- setdiff(wk_all[-1], c(0, 1))
max_z <- vapply(other_weeks, function(w) {
  max(abs(vapply(raw_vars, z_week, numeric(1), w = w)), na.rm = TRUE)
}, numeric(1))
obs_max <- max(abs(cont$z), na.rm = TRUE)
write_tab(tibble(
  statistic = "max over variables of |z|, restart week vs other weeks",
  restart_week_max = obs_max, var_at_max = cont$var[1],
  n_other_weeks = length(other_weeks),
  share_other_weeks_at_least = mean(max_z >= obs_max),
  other_weeks_median = median(max_z)
), "c4_03_weekly_global.csv")

# (b) One-year change at the restart (C4-M3) -----------------------------------------
# D_i = (first simulated year of run i) - (year 600 of its source chain).
# Under a seamless restart its distribution is that of a stationary one-year
# change of the cold-start chains, Y(t + 1) - Y(t) for t = 300 ... 599: mean
# 0 and the same variance. mean(D) has a point-bootstrap CI; the variance
# ratio uses independent bootstraps of points and cold chains.
vars <- c(key, state, proj)
t_ref <- LATE_START:(N_YEARS - 1)
one_year <- bind_rows(parallel::mclapply(vars, mc.cores = N_CORES,
  function(v) {
    yc <- cold$Y[[v]]
    D <- pool$first_year[[v]] - yc[N_YEARS, src[g]]
    dc <- yc[t_ref + 1, , drop = FALSE] - yc[t_ref, , drop = FALSE]
    sd_pi <- sqrt(pi_moments(yc, LATE_START:N_YEARS)$s2)
    f <- function(runs, cc) {
      c(mean(D[runs]) / sd_pi,
        var(D[runs]) / mean(apply(dc[, cc, drop = FALSE], 1, var)))
    }
    est <- f(seq_len(n_p), seq_len(ncol(yc)))
    bm <- do.call(rbind, lapply(seq_len(N_BOOT_PT), function(b) {
      f(point_boot_index(g)$runs, sample.int(ncol(yc), replace = TRUE))
    }))
    ci <- boot_ci(bm)
    tibble(var = v, block = dict$block[match(v, dict$name)],
      mean_change_sd = est[1], mean_lo = ci[1, 1], mean_hi = ci[1, 2],
      var_ratio = est[2], var_lo = ci[2, 1], var_hi = ci[2, 2])
  })) |>
  mutate(mean_excludes_0 = mean_lo > 0 | mean_hi < 0,
    var_excludes_1 = var_lo > 1 | var_hi < 1)
write_tab(one_year, "c4_03_one_year_change.csv")
cat("One-year change: mean CI excludes 0 for", sum(one_year$mean_excludes_0),
  "of", nrow(one_year), "; variance CI excludes 1 for",
  sum(one_year$var_excludes_1), "\n")

# Global test of the mean one-year changes (C4-M3): the variables are
# correlated, so single CIs overstate the evidence. Null: the same statistic
# (mean of one-year changes over 32 chains, weighted by the runs per point)
# computed on 32 cold-start chains drawn at random, at a random year
# t = 300 ... 598, without any restart. This null is conservative: it has one
# continuation per chain, the pool statistic averages several runs per point.
# Global p: the maximum over variables of |mean change| / null SD.
Dc <- lapply(setNames(vars, vars), function(v) {
  yc <- cold$Y[[v]]
  yc[t_ref + 1, , drop = FALSE] - yc[t_ref, , drop = FALSE]
})
wts <- nj / sum(nj)
null_mean <- t(vapply(seq_len(N_PERM), function(b) {
  cc <- sample.int(ncol(cold$Y[[1]]), length(nj))
  tt <- sample.int(length(t_ref) - 1, 1)
  vapply(vars, function(v) sum(Dc[[v]][tt, cc] * wts), numeric(1))
}, numeric(length(vars))))
obs_mean <- vapply(vars, function(v) {
  mean(pool$first_year[[v]] - cold$Y[[v]][N_YEARS, src[g]])
}, numeric(1))
sd_null <- apply(null_mean, 2, sd)
z_obs <- obs_mean / sd_null
max_null <- apply(abs(sweep(null_mean, 2, colMeans(null_mean)) /
  rep(sd_null, each = nrow(null_mean))), 1, max)
one_year_global <- tibble(
  statistic = "max |mean one-year change| / null SD",
  n_vars = length(vars), max_abs_z = max(abs(z_obs)),
  var_at_max = vars[which.max(abs(z_obs))],
  p_global = (1 + sum(max_null >= max(abs(z_obs)))) / (N_PERM + 1),
  n_abs_z_gt_2 = sum(abs(z_obs) > 2)
)
write_tab(one_year_global, "c4_03_one_year_global.csv")
one_year <- mutate(one_year, z_null = z_obs[var])
write_tab(one_year, "c4_03_one_year_change.csv")
print(as.data.frame(one_year_global))

# (c) Same stationary law? (C3-M2) --------------------------------------------------
# Years >= LATE_START of the pool runs against the cold-start runs (cycle 3)
# and against the x0 runs (cycle 1). At 300 years the runs of a point have
# long forgotten it (c4_04), so whole runs can be permuted as in c3_03.
Yx <- add_project_vars(readRDS(X0_ANNUAL_PATH)$Y)
rows <- LATE_START:N_YEARS
n_t <- length(rows)
cmp_vars <- intersect(c(key, state, proj), names(Yx))
compare_laws <- function(Ya, Yb, label) {
  na <- ncol(Ya[[1]])
  S <- setNames(lapply(cmp_vars, function(v) {
    rbind(chain_sums(Ya[[v]], rows), chain_sums(Yb[[v]], rows))
  }), cmp_vars)
  pt <- perm_test_moments(S, na, n_t, N_PERM)
  wv <- c(key, state)
  Yall <- lapply(setNames(wv, wv), function(v) cbind(Ya[[v]], Yb[[v]]))
  wh <- whiten(Yall, wv, rows, PCA_VAR)
  yrs <- seq(LATE_START, N_YEARS, by = ED_YEAR_STEP)
  et <- energy_chain_test(wh$Z[yrs, , , drop = FALSE],
    rep(c(TRUE, FALSE), c(na, ncol(Yb[[1]]))), N_PERM)
  list(
    per_var = mutate(pt$per_var, comparison = label,
      pct_diff = vapply(cmp_vars, function(v) {
        a <- group_moments(S[[v]][seq_len(na), ], n_t)["mu"]
        b <- group_moments(S[[v]][-seq_len(na), ], n_t)["mu"]
        unname(100 * (a / b - 1))
      }, numeric(1))),
    global = mutate(pt$global, comparison = label),
    energy = tibble(comparison = label, n_components = wh$n_comp,
      energy = et$stat, null_median = median(et$null),
      null_q95 = quantile(et$null, 0.95), p = et$p)
  )
}
cl <- compare_laws(pool$Y, cold$Y, "pool vs cold start")
xl <- compare_laws(pool$Y, Yx, "pool vs x0 runs")
laws <- bind_rows(cl$per_var, xl$per_var) |>
  mutate(block = dict$block[match(var, dict$name)])
write_tab(laws, "c4_03_law_compare.csv")
write_tab(bind_rows(cl$global, xl$global), "c4_03_law_global.csv")
write_tab(bind_rows(cl$energy, xl$energy), "c4_03_energy_test.csv")
print(as.data.frame(bind_rows(cl$global, xl$global)))
print(as.data.frame(bind_rows(cl$energy, xl$energy)))

# Figures ----------------------------------------------------------------------
show <- c("hiv.inf", "hiv.dx", "hiv.tx", "hiv.supp", "prep", "prep.indic",
  "gono.inf", "chla.inf", "syph.inf", "hiv.incid", "gono.incid", "num")
p <- seam |>
  select(week, all_of(show)) |>
  tidyr::pivot_longer(-week) |>
  mutate(side = ifelse(week <= 0, "source chains", "restarted runs")) |>
  ggplot(aes(week, value, colour = side)) +
  geom_vline(xintercept = 0, linetype = 2) +
  geom_line() +
  geom_point(size = 0.6) +
  facet_wrap(~name, scales = "free_y", ncol = 4) +
  labs(x = "Weeks relative to the restart (0 = the saved state)",
    y = "Cross-run mean (source chains weighted by runs per point)",
    colour = NULL,
    title = "Weekly continuity across a same-parameter restart") +
  theme(legend.position = "bottom")
save_fig(p, "c4_03_weekly_seam.png", 13, 9)

p <- laws |>
  filter(block %in% c("key", "project")) |>
  mutate(var = factor(var, rev(unique(var)))) |>
  ggplot(aes(z_mean, var, colour = comparison)) +
  geom_vline(xintercept = c(-2, 0, 2), linetype = c(3, 1, 3)) +
  geom_point() +
  labs(x = "Standardised mean difference (permutation z), years >= 300",
    y = NULL, colour = NULL,
    title = "Stationary means of the pool runs against the two earlier experiments") +
  theme(legend.position = "bottom")
save_fig(p, "c4_03_law_z.png", 9, 11)

save_session("c4_03")
