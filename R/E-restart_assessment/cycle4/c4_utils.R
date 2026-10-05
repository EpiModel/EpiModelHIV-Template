## Shared functions for cycle 4
##
## This script should not be run directly. But `sourced` from the scripts in
## `R/E-restart_assessment/cycle4/`, after `c4_config.R` (which loads the
## functions of cycles 1-3). Section numbers (C4-Mx) refer to
## `R/E-restart_assessment/cycle4/results/c4_METHODS.md`.

# Runs nested in restart points (C4-M2) ------------------------------------------

#' One-way random-effects decomposition of runs nested in restart points
#'
#' For every row of Y (a horizon, or a burn-in for a window functional),
#' with the runs grouped by restart point g (k points, n_j runs each,
#' N runs):
#'   sw2  = pooled within-point variance, divisor N - k;
#'   MS_B = sum_j n_j (ybar_j - ybar)^2 / (k - 1);
#'   n0   = (N - sum_j n_j^2 / N) / (k - 1);
#'   sb2  = (MS_B - sw2) / n0, the ANOVA estimator of the variance of
#'          E[Y | point] across points (can be negative).
#' Rows are centred first for numerical accuracy.
#' @param Y matrix [rows, runs]; g point of each run
#' @return list(sw2, sb2, msb) vectors over rows, and n0
nested_anova <- function(Y, g) {
  g <- as.integer(factor(g))
  k <- max(g)
  N <- length(g)
  nj <- tabulate(g, k)
  Yc <- Y - rowMeans(Y)
  S <- t(rowsum(t(Yc), g))
  ss_b <- rowSums(sweep(S^2, 2, nj, "/"))
  ss_w <- rowSums(Yc^2) - ss_b
  sw2 <- ss_w / (N - k)
  msb <- ss_b / (k - 1)
  n0 <- (N - sum(nj^2) / N) / (k - 1)
  list(sw2 = sw2, sb2 = (msb - sw2) / n0, msb = msb, n0 = n0)
}

#' Direct ICC estimates from the nested design (C4-M2)
#'
#' icc_w = 1 - sw2 / v_pi: the share of the stationary variance that runs
#'         from the same point do NOT show, i.e. the share fixed by the
#'         point. Precise (N - k df), but assumes the points are draws from
#'         pi, so that the total variance is v_pi.
#' icc_a = sb2 / (sb2 + sw2): the ANOVA intraclass correlation. It needs no
#'         pi reference, but rests on k points only.
#' @param v_pi stationary variance (scalar)
icc_direct <- function(Y, g, v_pi) {
  a <- nested_anova(Y, g)
  cbind(icc_w = 1 - a$sw2 / v_pi, icc_a = a$sb2 / (a$sb2 + a$sw2),
    w_ratio = a$sw2 / v_pi, sw2 = a$sw2, sb2 = a$sb2)
}

#' Run indices and new point labels for a bootstrap over restart points
#'
#' Points are drawn with replacement and keep all their runs. A point drawn
#' twice counts as two points (the usual cluster bootstrap).
#' @return list(runs, g)
point_boot_index <- function(g) {
  pts <- sort(unique(g))
  draw <- sample(pts, length(pts), replace = TRUE)
  runs <- lapply(draw, function(j) which(g == j))
  list(runs = unlist(runs),
    g = rep(seq_along(draw), times = lengths(runs)))
}

# Pool design (C4-M4) ---------------------------------------------------------------

#' Expected variance across runs, as a share of V = sb2 + sw2, when N runs
#' are spread over points with counts n_j (points iid from pi):
#'   E[s^2] / V = 1 - ICC * (sum_j n_j^2 / N - 1) / (N - 1)
pool_var_ratio <- function(icc, nj) {
  N <- sum(nj)
  1 - icc * (sum(nj^2) / N - 1) / (N - 1)
}

#' MCSE inflation of the mean of N runs spread over points with counts n_j,
#' relative to N runs from N independent points:
#'   Var(mean) = V / N * (1 + ICC * (sum_j n_j^2 / N - 1))
mcse_inflation <- function(icc, nj) sqrt(1 + icc * (sum(nj^2) / sum(nj) - 1))

#' Expected sum_j n_j^2 / N for N runs drawn uniformly with replacement from
#' k points (`randomize.restart = TRUE`): N / k + 1 - 1 / k
n_eff_random <- function(N, k) N / k + 1 - 1 / k
