## Shared functions for the restart-variance assessment
##
## This script should not be run directly. But `sourced` from the numbered
## scripts in `R/E-restart_assessment/`. Section numbers (e.g. M2.3) refer to
## `R/E-restart_assessment/METHODS.md`.
##
## Data convention: a variable is stored as a matrix `Y` with one row per year
## (1 ... T, years after restart) and one column per chain.

# Logging ----------------------------------------------------------------------

#' Save sessionInfo() for a step
#' @param step character step prefix, e.g. "03"
save_session <- function(step) {
  writeLines(
    capture.output(sessionInfo()),
    fs::path(LOG_DIR, paste0(step, "_sessionInfo.txt"))
  )
}

#' Write a table to results/tables/ (rounded for readability)
write_tab <- function(x, name, digits = 5) {
  x <- as.data.frame(x)
  num <- vapply(x, is.double, logical(1))
  x[num] <- lapply(x[num], signif, digits = digits)
  write.csv(x, fs::path(TAB_DIR, name), row.names = FALSE)
  invisible(x)
}

save_fig <- function(p, name, width = 9, height = 6) {
  ggplot2::ggsave(fs::path(FIG_DIR, name), p,
    width = width, height = height, dpi = 110
  )
}

# Basic moments ----------------------------------------------------------------

#' Cross-chain mean and variance per year (M2.1)
#' @return list(m, v) vectors of length nrow(Y)
cross_moments <- function(Y) {
  m <- rowMeans(Y)
  v <- rowSums((Y - m)^2) / (ncol(Y) - 1)
  list(m = m, v = v)
}

#' Stationary mean and variance estimated from the late period (M2.1)
#'
#' Pools all chains and all years in `rows`, using the global mean.
pi_moments <- function(Y, rows) {
  y <- Y[rows, , drop = FALSE]
  mu <- mean(y)
  list(mu = mu, s2 = mean((y - mu)^2))
}

#' Chain bootstrap: resample whole chains (columns) with replacement (M2.8)
#'
#' @param n_chain number of chains
#' @param B number of replicates
#' @param fun function(idx) returning a numeric vector; `idx` are the resampled
#'   column indices
#' @return B x length(fun(...)) matrix
chain_boot <- function(n_chain, B, fun) {
  out <- lapply(seq_len(B), function(b) {
    fun(sample.int(n_chain, n_chain, replace = TRUE))
  })
  do.call(rbind, out)
}

#' Percentile CI columns from a bootstrap matrix
boot_ci <- function(bm, probs = c(0.025, 0.975)) {
  t(apply(bm, 2, quantile, probs = probs, na.rm = TRUE))
}

# Drift tests (M2.2) -----------------------------------------------------------

#' OLS slope of y on x
ols_slope <- function(x, y) {
  xc <- x - mean(x)
  sum(xc * (y - mean(y))) / sum(xc^2)
}

#' Drift of the cross-chain mean and variance over a period
#'
#' Mean drift is expressed in SD_pi per century, variance drift as relative
#' change per century. SD_pi and v_pi come from the same period so the test
#' is self-contained.
#' @param Y year x chain matrix
#' @param years integer vector of years (rows) in the period
#' @return named vector (mean_drift, var_drift)
drift_stats <- function(Y, years) {
  cm <- cross_moments(Y[years, , drop = FALSE])
  pm <- pi_moments(Y, years)
  c(
    mean_drift = 100 * ols_slope(years, cm$m) / sqrt(pm$s2),
    var_drift  = 100 * ols_slope(years, cm$v) / pm$s2
  )
}

# Distances between distributions (M2.4) ---------------------------------------

#' Euclidean distance matrix between the rows of A and the rows of B
pdist <- function(A, B) {
  a2 <- rowSums(A^2)
  b2 <- rowSums(B^2)
  sqrt(pmax(outer(a2, b2, "+") - 2 * tcrossprod(A, B), 0))
}

#' Energy distance, V-statistic version (M2.4)
#'
#' E = 2 mean|x - y| - mean|x - x'| - mean|y - y'|, diagonals included.
#' @param X,Y matrices (rows = observations) on a standardised scale
#' @param yy optional precomputed mean|y - y'|
energy_v <- function(X, Y, yy = NULL) {
  if (is.null(yy)) yy <- mean(pdist(Y, Y))
  2 * mean(pdist(X, Y)) - mean(pdist(X, X)) - yy
}

#' Wasserstein-1 distance between two univariate samples
#'
#' Computed on the quantile functions evaluated on a common grid, which is
#' exact for equal sample sizes and a close approximation otherwise.
w1 <- function(a, b, n_grid = 256) {
  p <- (seq_len(n_grid) - 0.5) / n_grid
  mean(abs(quantile(a, p, names = FALSE, type = 1) -
    quantile(b, p, names = FALSE, type = 1)))
}

#' First-passage rule for the time to stationarity (M2.5)
#'
#' Returns the smallest evaluated year t such that over [t, late_start] the
#' statistic D exceeds the null quantile q in at most (1 - q_level) of the
#' evaluated years, and never more than `max_run` times in a row.
#' @param D statistic, one value per evaluated year
#' @param years years at which D was evaluated
#' @param q null threshold
t_rule <- function(D, years, q, late_start, q_level, max_run) {
  sel <- years <= late_start
  D <- D[sel]
  years <- years[sel]
  exc <- D > q
  n <- length(exc)
  # For every start index, the fraction of exceedances and the longest run
  # over the remaining years (computed backwards).
  ok <- logical(n)
  run <- 0
  longest <- 0
  n_exc <- 0
  for (i in rev(seq_len(n))) {
    run <- if (exc[i]) run + 1 else 0
    longest <- max(longest, run)
    n_exc <- n_exc + exc[i]
    ok[i] <- (n_exc / (n - i + 1) <= 1 - q_level) && longest <= max_run
  }
  # smallest i such that all later start points would also be accepted is not
  # required; the definition only needs the window [t, late_start]
  if (!any(ok)) {
    return(NA_real_)
  }
  years[min(which(ok))]
}

# Time structure (M2.6, M2.7) --------------------------------------------------

#' Pooled autocorrelation with the global mean and variance (M2.6)
#'
#' rho(k) = mean over chains and t of (Y_t - mu)(Y_{t+k} - mu) / s2.
#' No per-chain demeaning, which would bias slow modes downward.
pooled_acf <- function(Y, max_lag, mu = mean(Y), s2 = mean((Y - mu)^2)) {
  Z <- Y - mu
  n <- nrow(Z)
  vapply(0:max_lag, function(k) {
    mean(Z[1:(n - k), , drop = FALSE] * Z[(1 + k):n, , drop = FALSE]) / s2
  }, numeric(1))
}

#' Integrated autocorrelation time with Geyer's initial monotone sequence
#'
#' tau = 1 + 2 sum_{k >= 1} rho(k), truncated where the sums of consecutive
#' pairs Gamma_m = rho(2m) + rho(2m + 1) stop being positive, and made
#' monotone. `rho` starts at lag 0.
#' @return list(tau, truncated) where truncated = TRUE if the sequence was
#'   still positive at the largest lag (tau is then a lower value)
tau_geyer <- function(rho) {
  n_pairs <- floor(length(rho) / 2)
  G <- rho[2 * seq_len(n_pairs) - 1] + rho[2 * seq_len(n_pairs)]
  pos <- which(G <= 0)
  m <- if (length(pos)) pos[1] - 1 else n_pairs
  if (m < 1) {
    return(list(tau = 1, truncated = FALSE))
  }
  G <- cummin(G[seq_len(m)])
  list(tau = -1 + 2 * sum(G), truncated = length(pos) == 0)
}

#' Non-overlapping window means and within-window variances (M2.7)
#'
#' @param Y year x chain matrix
#' @param L window length
#' @param start first year of the first window
#' @return list(M, S2): windows x chains matrices; S2 uses divisor L
window_stats <- function(Y, L, start) {
  n_win <- floor((nrow(Y) - start + 1) / L)
  idx <- start + seq_len(n_win * L) - 1
  x <- Y[idx, , drop = FALSE]
  dim(x) <- c(L, n_win * ncol(Y))
  M <- colMeans(x)
  S2 <- pmax(colMeans(x^2) - M^2, 0)
  list(M = matrix(M, n_win), S2 = matrix(S2, n_win))
}

#' Window decomposition Var_pi = E[S2_L] + Var(M_L), global mean (M2.7)
#' @return named vector with both terms, their sum and the pooled variance
window_split <- function(Y, L, start) {
  ws <- window_stats(Y, L, start)
  n_win <- nrow(ws$M)
  y <- Y[start + seq_len(n_win * L) - 1, , drop = FALSE]
  mu <- mean(y)
  c(
    within  = mean(ws$S2),
    between = mean((ws$M - mu)^2),
    total   = mean((y - mu)^2)
  )
}

#' Variance-time curve L * Var(M_L) / Var_pi (M2.7)
variance_time <- function(Y, L_grid, start) {
  y <- Y[start:nrow(Y), , drop = FALSE]
  mu <- mean(y)
  s2 <- mean((y - mu)^2)
  vapply(L_grid, function(L) {
    M <- window_stats(Y, L, start)$M
    L * mean((M - mu)^2) / s2
  }, numeric(1))
}

# Relaxation fits (M2.5) -------------------------------------------------------

#' Fit the variance-ratio relaxation r(t) = v(t) / v_pi
#'
#' Models: (1) 1 - c1 exp(-t / tau1); (2) 1 - c1 exp(-t / tau1) -
#' c2 exp(-t / tau2). Fitted by least squares with multiple starts; the best
#' by AIC is returned (residuals are autocorrelated, so AIC is indicative).
#' @return list(model, coef, fitted function)
fit_var_relax <- function(t, r) {
  f1 <- function(p, t) 1 - p[1] * exp(-t / p[2])
  f2 <- function(p, t) 1 - p[1] * exp(-t / p[2]) - p[3] * exp(-t / p[4])
  try_fit <- function(f, starts, lower, upper) {
    best <- NULL
    for (s in starts) {
      fit <- tryCatch(
        minpack.lm::nls.lm(s, lower, upper,
          fn = function(p) r - f(p, t),
          control = minpack.lm::nls.lm.control(maxiter = 500)
        ),
        error = function(e) NULL
      )
      if (!is.null(fit) && (is.null(best) || fit$deviance < best$deviance)) {
        best <- fit
      }
    }
    best
  }
  fit1 <- try_fit(f1,
    list(c(1, 2), c(1, 10), c(1, 40)),
    c(0, 0.1), c(2, 1000)
  )
  fit2 <- try_fit(f2,
    list(c(0.8, 1, 0.2, 20), c(0.5, 3, 0.5, 50), c(0.9, 0.5, 0.1, 100)),
    c(0, 0.1, 0, 0.1), c(2, 1000, 2, 1000)
  )
  n <- length(r)
  aic <- function(fit, k) n * log(fit$deviance / n) + 2 * k
  a1 <- if (is.null(fit1)) Inf else aic(fit1, 2)
  a2 <- if (is.null(fit2)) Inf else aic(fit2, 4)
  if (a2 < a1 - 2) {
    p <- fit2$par
    # order the two components by time constant
    if (p[2] > p[4]) p <- p[c(3, 4, 1, 2)]
    list(model = "2exp", coef = p, aic = c(a1, a2), fn = function(t) f2(p, t))
  } else {
    p <- fit1$par
    list(model = "1exp", coef = c(p, NA, NA), aic = c(a1, a2),
      fn = function(t) f1(p, t))
  }
}

# Ridge regression with chain-blocked CV (M2.3) --------------------------------

#' Standardise columns of X with the given centre and scale
scale_with <- function(X, ctr, scl) {
  sweep(sweep(X, 2, ctr, "-"), 2, scl, "/")
}

#' Ridge predictions for a set of lambdas, computed through one SVD
#'
#' @param Xtr,Ytr training features and responses (Y may have many columns)
#' @param Xte test features
#' @param lambdas penalties, relative to the number of training rows
#' @return array [n_test, n_resp, n_lambda] of predictions
ridge_path <- function(Xtr, Ytr, Xte, lambdas) {
  ctr <- colMeans(Xtr)
  scl <- apply(Xtr, 2, sd)
  scl[scl == 0] <- 1
  Xtr <- scale_with(Xtr, ctr, scl)
  Xte <- scale_with(Xte, ctr, scl)
  ymu <- colMeans(Ytr)
  Yc <- sweep(Ytr, 2, ymu, "-")
  s <- svd(Xtr)
  UtY <- crossprod(s$u, Yc)
  XteV <- Xte %*% s$v
  n <- nrow(Xtr)
  out <- array(NA_real_, c(nrow(Xte), ncol(Ytr), length(lambdas)))
  for (j in seq_along(lambdas)) {
    f <- s$d / (s$d^2 + lambdas[j] * n)
    out[, , j] <- sweep(XteV %*% (UtY * f), 2, ymu, "+")
  }
  out
}

#' Out-of-sample ridge predictions with chain-blocked folds
#'
#' Lambda is chosen per response by an inner chain-blocked CV inside each
#' outer training set. Standardisation uses training rows only.
#' @param X features, Y responses (matrices with the same rows)
#' @param chain chain id of each row
#' @param n_folds outer folds; inner CV uses 4 folds
#' @return matrix of out-of-fold predictions, same shape as Y
ridge_cv <- function(X, Y, chain, n_folds, lambdas) {
  chains <- unique(chain)
  fold_of <- setNames(rep_len(seq_len(n_folds), length(chains)),
    sample(chains))
  fold <- fold_of[as.character(chain)]
  pred <- matrix(NA_real_, nrow(Y), ncol(Y), dimnames = dimnames(Y))
  for (f in seq_len(n_folds)) {
    tr <- which(fold != f)
    te <- which(fold == f)
    # inner CV to select lambda per response
    tr_chains <- unique(chain[tr])
    inner_of <- setNames(rep_len(1:4, length(tr_chains)), sample(tr_chains))
    inner <- inner_of[as.character(chain[tr])]
    sse <- matrix(0, ncol(Y), length(lambdas))
    for (g in 1:4) {
      itr <- tr[inner != g]
      ite <- tr[inner == g]
      p <- ridge_path(X[itr, , drop = FALSE], Y[itr, , drop = FALSE],
        X[ite, , drop = FALSE], lambdas)
      for (j in seq_along(lambdas)) {
        sse[, j] <- sse[, j] + colSums((Y[ite, , drop = FALSE] - p[, , j])^2)
      }
    }
    best <- apply(sse, 1, which.min)
    p <- ridge_path(X[tr, , drop = FALSE], Y[tr, , drop = FALSE],
      X[te, , drop = FALSE], lambdas)
    for (r in seq_len(ncol(Y))) pred[te, r] <- p[, r, best[r]]
  }
  pred
}

#' Out-of-sample R^2 against a fixed reference mean (M2.3)
r2_oos <- function(y, yhat, ybar = mean(y)) {
  1 - sum((y - yhat)^2) / sum((y - ybar)^2)
}

# Pseudo-restarts (M2.3) -------------------------------------------------------

#' Rows of (chain, t0) pseudo-restart points
restart_rows <- function(t0s, n_chain) {
  expand.grid(t0 = t0s, chain = seq_len(n_chain))
}

#' Features known at the restart: values at t0 and t0 - lag for each lag
#'
#' Only information at or before t0 enters (M2.3).
#' @param Ylist named list of year x chain matrices
#' @return matrix, one row per pseudo-restart
restart_features <- function(Ylist, vars, rows, lags = integer(0)) {
  out <- list()
  for (v in vars) {
    for (l in c(0, lags)) {
      out[[paste0(v, "_l", l)]] <- Ylist[[v]][cbind(rows$t0 - l, rows$chain)]
    }
  }
  do.call(cbind, out)
}

#' Value h years after the restart
restart_value <- function(Y, rows, h) Y[cbind(rows$t0 + h, rows$chain)]

#' Window functionals over years t0 + B + 1 ... t0 + B + L (M2.7)
#' @return data.frame with mean (M), within variance (S2, divisor L) and
#'   OLS slope per year
restart_window <- function(Y, rows, L, B = 0) {
  idx <- outer(rows$t0 + B, seq_len(L), "+")
  vals <- matrix(Y[cbind(as.vector(idx), rep(rows$chain, L))], ncol = L)
  M <- rowMeans(vals)
  x <- seq_len(L) - (L + 1) / 2
  data.frame(
    M = M,
    S2 = rowMeans((vals - M)^2),
    slope = as.vector(vals %*% x) / sum(x^2)
  )
}

#' Chain-bootstrap CI for an out-of-sample R^2 (M2.3)
#' @return c(est, lo, hi)
r2_boot <- function(y, yhat, ybar, chain, B) {
  res2 <- (y - yhat)^2
  tot2 <- (y - ybar)^2
  by_c <- rowsum(cbind(res2, tot2), chain)
  est <- 1 - sum(res2) / sum(tot2)
  bs <- replicate(B, {
    i <- sample.int(nrow(by_c), replace = TRUE)
    1 - sum(by_c[i, 1]) / sum(by_c[i, 2])
  })
  c(est = est, quantile(bs, c(0.025, 0.975), names = FALSE))
}

# Multivariate convergence (M2.4, M2.5) ----------------------------------------

#' Standardise by pi moments and whiten with a PCA on the pi covariance
#'
#' Redundant variables would otherwise dominate the energy distance (M2.4).
#' @param Ylist named list of year x chain matrices
#' @param pi_rows years used to estimate pi
#' @param var_keep fraction of variance kept
#' @return list(Z = array [year, chain, component], n_comp, var_explained)
whiten <- function(Ylist, vars, pi_rows, var_keep) {
  n_y <- nrow(Ylist[[1]])
  n_c <- ncol(Ylist[[1]])
  S <- vapply(vars, function(v) {
    pm <- pi_moments(Ylist[[v]], pi_rows)
    as.vector((Ylist[[v]] - pm$mu) / sqrt(pm$s2))
  }, numeric(n_y * n_c))
  in_pi <- rep(seq_len(n_y), n_c) %in% pi_rows
  e <- eigen(cov(S[in_pi, ]), symmetric = TRUE)
  cum <- cumsum(e$values) / sum(e$values)
  k <- which(cum >= var_keep)[1]
  Z <- S %*% e$vectors[, 1:k, drop = FALSE] %*%
    diag(1 / sqrt(e$values[1:k]), k)
  list(Z = array(Z, c(n_y, n_c, k)), n_comp = k, var_explained = cum[k])
}

#' Energy distance between half A at each year and half B at reference years
#'
#' For each random half-split of the chains, the reference is the pooled
#' vectors of half B at `ref_years`. The halves are independent, so values
#' for years >= LATE_START form a null sample (M2.5).
#' @param Z array [year, chain, component]
#' @return matrix [length(eval_years), n_splits]
energy_trajectory <- function(Z, eval_years, ref_years, n_splits) {
  n_c <- dim(Z)[2]
  sapply(seq_len(n_splits), function(s) {
    A <- sample(n_c, floor(n_c / 2))
    Bc <- setdiff(seq_len(n_c), A)
    ref <- do.call(rbind, lapply(ref_years, function(t) {
      matrix(Z[t, Bc, ], ncol = dim(Z)[3])
    }))
    yy <- mean(pdist(ref, ref))
    vapply(eval_years, function(t) {
      energy_v(matrix(Z[t, A, ], ncol = dim(Z)[3]), ref, yy)
    }, numeric(1))
  })
}

#' Univariate distances between half A at each year and half B at ref years
#'
#' Statistics on the pi-standardised scale: W1, absolute mean difference and
#' absolute log variance ratio (M2.5).
#' @param z year x chain matrix, standardised by pi moments
#' @return array [length(eval_years), 3, n_splits]
uni_trajectory <- function(z, eval_years, ref_years, n_splits) {
  n_c <- ncol(z)
  out <- sapply(seq_len(n_splits), function(s) {
    A <- sample(n_c, floor(n_c / 2))
    Bc <- setdiff(seq_len(n_c), A)
    ref <- as.vector(z[ref_years, Bc])
    mr <- mean(ref)
    vr <- var(ref)
    t(vapply(eval_years, function(t) {
      a <- z[t, A]
      c(w1 = w1(a, ref), mean = abs(mean(a) - mr),
        logvar = abs(log(var(a) / vr)))
    }, numeric(3)))
  }, simplify = "array")
  out
}

#' Time to stationarity calibrated on the null (M2.5, replaces `t_rule`)
#'
#' D(t) is autocorrelated in t (the same chains are followed over time), so
#' rules that count exceedances year by year declare stationarity far too
#' late (see 02_validate_methods.md). Instead:
#'   1. smooth D with a centred running mean of width `smooth_w` years;
#'   2. the threshold is the maximum (or a high quantile) of the smoothed D
#'      over the null period [late_start, end], a 300-year stationary stretch;
#'   3. T is the year after the last exceedance before `late_start`.
#' With the maximum, a stationary stretch shorter than the null period
#' exceeds the threshold with probability below 1/2, so T is not pushed late
#' by chance; T is the time after which the data cannot distinguish L_t from
#' pi at the worst level seen in 300 stationary years.
#' @param D statistic evaluated every year 1 ... T
#' @param type "max" or a quantile level such as 0.99
t_full_rule <- function(D, late_start, smooth_w, type = "max") {
  Ds <- as.vector(stats::filter(D, rep(1 / smooth_w, smooth_w), sides = 2))
  null <- Ds[late_start:length(Ds)]
  thr <- if (type == "max") max(null, na.rm = TRUE) else
    quantile(null, as.numeric(type), na.rm = TRUE)
  pre <- which(Ds[seq_len(late_start - 1)] > thr)
  list(t = if (length(pre)) max(pre) + 1 else 1, threshold = thr,
    smoothed = Ds)
}

#' Fit the relaxation of the standardised mean offset o(t) = (m(t) - mu) / SD
#'
#' mu and SD are the pi moments, so o(t) -> 0. Models: (a) A1 exp(-t/tau1);
#' (b) (a) + A2 exp(-t/tau2); (c) A exp(-t/tau) cos(omega t + phi).
#' Least squares with multiple starts, selection by AIC (indicative only,
#' residuals are autocorrelated).
fit_mean_relax <- function(t, o) {
  fa <- function(p, t) p[1] * exp(-t / p[2])
  fb <- function(p, t) p[1] * exp(-t / p[2]) + p[3] * exp(-t / p[4])
  fc <- function(p, t) p[1] * exp(-t / p[2]) * cos(p[3] * t + p[4])
  best_fit <- function(f, starts, lower, upper) {
    best <- NULL
    for (s in starts) {
      fit <- tryCatch(
        minpack.lm::nls.lm(s, lower, upper,
          fn = function(p) o - f(p, t),
          control = minpack.lm::nls.lm.control(maxiter = 500)
        ),
        error = function(e) NULL
      )
      if (!is.null(fit) && (is.null(best) || fit$deviance < best$deviance)) {
        best <- fit
      }
    }
    best
  }
  a0 <- o[1]
  fits <- list(
    `1exp` = best_fit(fa, list(c(a0, 2), c(a0, 10), c(a0, 50)),
      c(-50, 0.1), c(50, 1000)),
    `2exp` = best_fit(fb,
      list(c(a0, 2, -a0 / 2, 30), c(a0, 5, a0 / 2, 60), c(-a0, 3, a0, 20)),
      c(-50, 0.1, -50, 0.1), c(50, 1000, 50, 1000)),
    damped_cos = best_fit(fc,
      list(c(a0, 20, 0.1, 0), c(a0, 40, 0.05, 0), c(a0, 10, 0.3, 0)),
      c(-50, 0.1, 0, -pi), c(50, 1000, pi, pi))
  )
  f_list <- list(`1exp` = fa, `2exp` = fb, damped_cos = fc)
  k <- c(`1exp` = 2, `2exp` = 4, damped_cos = 4)
  n <- length(o)
  aic <- vapply(names(fits), function(m) {
    if (is.null(fits[[m]])) Inf else n * log(fits[[m]]$deviance / n) + 2 * k[m]
  }, numeric(1))
  # a more complex model must improve the AIC by at least 2
  m <- if (min(aic[-1]) < aic[1] - 2) names(which.min(aic)) else "1exp"
  p <- fits[[m]]$par
  list(model = m, coef = p, aic = aic, fn = function(t) f_list[[m]](p, t))
}

#' Time after which a fitted deficit stays within a tolerance
#'
#' @param fn fitted deficit function of t (e.g. 1 - r(t), or |o(t)|)
#' @param eps tolerance
#' @param t_max search horizon
#' @return year after the last t <= t_max with |fn(t)| > eps (0 if none)
t_from_fit <- function(fn, eps, t_max = 2000) {
  tt <- seq(0, t_max, by = 0.25)
  over <- which(abs(fn(tt)) > eps)
  if (!length(over)) return(0)
  if (max(over) == length(tt)) return(Inf)
  tt[max(over) + 1]
}

# Fast pooled ACF for chain bootstraps (M2.6) ----------------------------------

#' Per-chain sums from which the pooled ACF can be recomputed for any subset
#' of chains and any global mean, exactly:
#'   sum_t (y_t - mu)(y_{t+k} - mu) = P_k - mu (A_k + B_k) + (n - k) mu^2
#' with P_k = sum y_t y_{t+k}, A_k = sum_{t <= n-k} y_t, B_k = sum_{t > k} y_t.
#' P is computed with zero-padded FFTs.
#' @return list(P, A, B: (max_lag + 1) x chain matrices; S1, S2: colSums of y
#'   and y^2; n)
acf_parts <- function(Y, max_lag) {
  n <- nrow(Y)
  m <- 2^ceiling(log2(2 * n))
  F <- mvfft(rbind(Y, matrix(0, m - n, ncol(Y))))
  P <- Re(mvfft(Mod(F)^2, inverse = TRUE))[1:(max_lag + 1), , drop = FALSE] / m
  cs <- rbind(0, apply(Y, 2, cumsum))
  k <- 0:max_lag
  A <- cs[n - k + 1, , drop = FALSE]
  B <- sweep(-cs[k + 1, , drop = FALSE], 2, cs[n + 1, ], "+")
  list(P = P, A = A, B = B, S1 = colSums(Y), S2 = colSums(Y^2), n = n)
}

#' Pooled ACF (global mean and variance) for the chains in `idx`
acf_from_parts <- function(parts, idx = seq_along(parts$S1)) {
  n <- parts$n
  nc <- length(idx)
  mu <- sum(parts$S1[idx]) / (n * nc)
  s2 <- sum(parts$S2[idx]) / (n * nc) - mu^2
  k <- 0:(nrow(parts$P) - 1)
  num <- rowSums(parts$P[, idx, drop = FALSE]) -
    mu * rowSums(parts$A[, idx, drop = FALSE] + parts$B[, idx, drop = FALSE]) +
    nc * (n - k) * mu^2
  num / (nc * (n - k)) / s2
}
