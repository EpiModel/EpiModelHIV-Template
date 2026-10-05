# =============================================================================
# c4_04_icc_direct.R
# Question : What share of the variance of an output is fixed by the restart
#            state, measured DIRECTLY and averaged over states drawn from pi
#            (32 points x 1-15 runs), including the memory held in the
#            network and in individual histories that the lower bounds of
#            cycles 1-3 cannot see? How long does a single same-parameter
#            restart point take to reach full variance?
# Inputs   : data/run/restart_assessment/cycle4/c4_01_annual_pool.rds,
#            data/run/restart_assessment/cycle3/c3_01_annual_cold.rds,
#            cycle3/results/tables/c3_06_icc_bounds.csv,
#            results/tables/06_icc_bounds.csv, 04_icc_x0.csv,
#            04_window_burnin.csv (cycle 1)
# Outputs  : cycle4/results/tables/c4_04_*.csv, figures/c4_04_*.png,
#            data/run/restart_assessment/cycle4/c4_04_icc.rds
# Method   : c4_METHODS.md C4-M2; results/c4_04_icc_direct.md
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
proj <- dict$name[dict$block == "project" & !grepl("^cml_incid", dict$name)]
vars <- c(key, proj)
cml <- c("hiv.incid", "hiv.incid.B", "hiv.incid.H", "hiv.incid.W")
g <- pool$point
pi_rows <- LATE_START:N_YEARS
hs <- seq_len(H_MAX)
Bs <- 0:B_MAX

# Direct ICC for values, 20-year means and 10-year cumulative incidence --------
# For a set of runs (and their point labels): values at h = 1 ... H_MAX,
# 20-year means over years B + 1 ... B + 20 and 10-year sums over years
# B + 1 ... B + 10 (B = 5 is the project's years 6-15), for B = 0 ... B_MAX.
# The pi references come from years >= LATE_START of the same runs, which
# c4_03 found to follow pi_cold.
icc_all <- function(y, runs, gg, fun_type) {
  yy <- y[, runs, drop = FALSE]
  out <- list()
  if ("value" %in% fun_type) {
    out$value <- icc_direct(yy[hs, , drop = FALSE], gg,
      pi_moments(yy, pi_rows)$s2)
  }
  if ("M20" %in% fun_type) {
    M <- window_from_x0(yy, WINDOW_L, Bs, "mean")
    out$M20 <- icc_direct(M, gg,
      window_ref(yy, WINDOW_L, LATE_START, 1, "mean")["var"])
  }
  if ("cml10" %in% fun_type) {
    M <- window_from_x0(yy, INT_L, Bs, "sum")
    out$cml10 <- icc_direct(M, gg,
      window_ref(yy, INT_L, LATE_START, 1, "sum")["var"])
  }
  out
}
defs <- c(
  lapply(setNames(vars, vars), function(v) c("value", "M20")),
  lapply(setNames(cml, cml), function(v) "cml10")
)
res <- parallel::mclapply(names(defs), mc.cores = N_CORES, function(v) {
  y <- pool$Y[[v]]
  est <- icc_all(y, seq_along(g), g, defs[[v]])
  bm <- lapply(seq_len(N_BOOT_PT), function(b) {
    bi <- point_boot_index(g)
    icc_all(y, bi$runs, bi$g, defs[[v]])
  })
  # pi_cold reference, as a check that the result does not hinge on the
  # pool's own late years
  vc <- pi_moments(cold$Y[[v]], pi_rows)$s2
  bind_rows(lapply(names(est), function(f) {
    q <- function(col) {
      m <- vapply(bm, function(b) b[[f]][, col], numeric(nrow(est[[f]])))
      t(apply(m, 1, quantile, c(0.025, 0.975), na.rm = TRUE))
    }
    qw <- q("icc_w")
    qa <- q("icc_a")
    tibble(var = v, functional = f,
      h = if (f == "value") hs else Bs,
      icc_w = est[[f]][, "icc_w"], icc_w_lo = qw[, 1], icc_w_hi = qw[, 2],
      icc_a = est[[f]][, "icc_a"], icc_a_lo = qa[, 1], icc_a_hi = qa[, 2],
      w_ratio = est[[f]][, "w_ratio"],
      icc_w_pi_cold = if (f == "value") 1 - est[[f]][, "sw2"] / vc else NA)
  }))
})
icc <- bind_rows(res)
saveRDS(icc, fs::path(INTER4_DIR, "c4_04_icc.rds"))
write_tab(icc, "c4_04_icc_all.csv")

sum_tab <- icc |>
  filter((functional == "value" & h %in% H_REPORT) |
    (functional != "value" & h %in% B_REPORT)) |>
  transmute(var, functional, h,
    icc_w = fmt_ci(icc_w, icc_w_lo, icc_w_hi),
    icc_a = fmt_ci(icc_a, icc_a_lo, icc_a_hi))
write_tab(sum_tab, "c4_04_icc_summary.csv")

# A single same-parameter restart point: time to full variance (C4-M2) ----------
# The runs of one point have variance w(h) = sw2(h) / v_pi = 1 - ICC(h),
# averaged over points drawn from pi. T(eps) = year after which the fitted
# 1 - w stays <= eps, with the cycle 3 variance model (validated in c4_02);
# the same over B for the window functionals. CIs: point-bootstrap refits.
t_one <- function(w, t) {
  fv <- fit_var_relax_c3(t, w)
  vapply(EPS_ICC, function(e) t_from_fit(function(tt) 1 - fv$fn(tt), e),
    numeric(1))
}
one_pt <- bind_rows(parallel::mclapply(names(defs), mc.cores = N_CORES,
  function(v) {
    y <- pool$Y[[v]]
    est <- icc_all(y, seq_along(g), g, defs[[v]])
    bind_rows(lapply(names(est), function(f) {
      t <- if (f == "value") hs else Bs
      tt <- if (f == "value") t else t + 1 # fits need t > 0
      e <- t_one(est[[f]][, "w_ratio"], tt)
      bm <- do.call(rbind, lapply(seq_len(N_BOOT_FIT), function(b) {
        bi <- point_boot_index(g)
        t_one(icc_all(y, bi$runs, bi$g, f)[[f]][, "w_ratio"], tt)
      }))
      ci <- boot_ci(bm)
      if (f != "value") { # back to the burn-in scale
        e <- pmax(e - 1, 0)
        ci <- pmax(ci - 1, 0)
      }
      tibble(var = v, functional = f, eps = EPS_ICC, T = e, lo = ci[, 1],
        hi = ci[, 2])
    }))
  }))
write_tab(one_pt, "c4_04_one_point_T.csv")

# Against the lower bounds and the single-x0 values of earlier cycles -----------
# Lower bounds of the same (cold-start) model: c3_06, cold start; of the x0
# model: cycle 1. The gap icc_w - LB is the memory that the observed state
# summaries do not carry (network, individual histories).
lb_cold <- read.csv(fs::path(C3_TAB_DIR, "c3_06_icc_bounds.csv")) |>
  filter(start == "cold start") |>
  transmute(var, functional = recode(functional, window_mean = "M20"), h,
    lb_cold = icc_lb, lb_cold_lo = icc_lb_lo, lb_cold_hi = icc_lb_hi)
lb_x0 <- read.csv(fs::path(C1_TAB_DIR, "06_icc_bounds.csv")) |>
  transmute(var, functional = recode(functional, window_mean = "M20"), h,
    lb_x0_cycle1 = icc_lb)
direct_x0 <- bind_rows(
  read.csv(fs::path(C1_TAB_DIR, "04_icc_x0.csv")) |>
    transmute(var, functional = "value", h, x0_single_point = icc),
  read.csv(fs::path(C1_TAB_DIR, "04_window_burnin.csv")) |>
    transmute(var, functional = "M20", h = B, x0_single_point = 1 - between)
)
vs <- icc |>
  select(var, functional, h, icc_w, icc_w_lo, icc_w_hi) |>
  inner_join(lb_cold, by = c("var", "functional", "h")) |>
  left_join(lb_x0, by = c("var", "functional", "h")) |>
  left_join(direct_x0, by = c("var", "functional", "h")) |>
  mutate(unobserved = icc_w - lb_cold,
    lb_inside_ci = lb_cold >= icc_w_lo & lb_cold <= icc_w_hi)
write_tab(vs, "c4_04_vs_bounds.csv")
print(as.data.frame(vs |> filter(var %in% c("prev", "num", "incid_rate",
  "dx_frac", "gono_prev", "syph_prev", "hiv.incid"))), digits = 3)

# Figures ----------------------------------------------------------------------
show <- c("prev", "prev.B", "prev.H", "prev.W", "i.prev.dx.B", "num",
  "incid_rate", "dx_frac", "supp_frac", "prep_cov", "gono_prev", "chla_prev",
  "syph_prev", "ir100.gono", "cc.vsupp.B", "disease.mr100")
x0v <- direct_x0 |> filter(functional == "value", var %in% show)
p <- icc |>
  filter(functional == "value", var %in% show, h <= 100) |>
  mutate(var = factor(var, show)) |>
  ggplot(aes(h)) +
  geom_hline(yintercept = 0) +
  geom_hline(yintercept = 0.1, linetype = 3) +
  geom_ribbon(aes(ymin = icc_w_lo, ymax = icc_w_hi), fill = "steelblue",
    alpha = 0.3) +
  geom_line(aes(y = icc_w, colour = "direct, 32 points from pi")) +
  geom_line(data = x0v |> mutate(var = factor(var, show)) |> filter(h <= 100),
    aes(y = x0_single_point, colour = "direct, x0 only (cycle 1)"),
    linewidth = 0.3) +
  geom_point(data = lb_cold |> filter(functional == "value", var %in% show) |>
      mutate(var = factor(var, show)),
    aes(y = lb_cold, colour = "lower bound, cold-start model (c3_06)")) +
  facet_wrap(~var, ncol = 4) +
  coord_cartesian(ylim = c(-0.2, 1)) +
  scale_colour_manual(values = c("steelblue4", "grey50", "darkorange")) +
  labs(x = "Years after the restart (h)", y = "ICC(h)", colour = NULL,
    title = "Share of the variance fixed by the restart state, measured directly",
    subtitle = "Band: 95% bootstrap over restart points") +
  theme(legend.position = "bottom")
save_fig(p, "c4_04_icc_values.png", 13, 13)

p <- icc |>
  filter(functional != "value", var %in% c(show, cml)) |>
  ggplot(aes(h, icc_w)) +
  geom_hline(yintercept = 0) +
  geom_hline(yintercept = 0.1, linetype = 3) +
  geom_ribbon(aes(ymin = icc_w_lo, ymax = icc_w_hi), alpha = 0.3,
    fill = "steelblue") +
  geom_line() +
  geom_point(data = lb_cold |> filter(functional != "value",
      var %in% c(show, cml)), aes(y = lb_cold), colour = "darkorange") +
  facet_wrap(~ paste(var, functional), ncol = 5) +
  coord_cartesian(ylim = c(-0.2, 1)) +
  labs(x = "Burn-in B before the window (years)", y = "ICC of the window",
    title = "Share of the variance of research windows fixed by the restart state",
    subtitle = paste0("M20: 20-year mean over years B+1...B+20; cml10: HIV ",
      "infections over years B+1...B+10. Orange: lower bounds (c3_06)."))
save_fig(p, "c4_04_icc_windows.png", 15, 12)

save_session("c4_04")
