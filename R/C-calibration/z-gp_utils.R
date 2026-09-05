mscale <- function(x, rnge) (x - rnge[1]) / diff(rnge)
munscale <- function(x, rnge) x * diff(rnge) + rnge[1]

#' Credible Interval on a Contour Location via Conditional Simulation
#'
#' Estimates the input location at which a fitted Gaussian process crosses a
#' target output level, together with a credible interval on that location.
#' Rather than summarising uncertainty about the \emph{output} at fixed inputs
#' (as \code{\link[stats]{predict}} does), this function summarises uncertainty
#' about the \emph{input} at which a fixed output is attained --- the quantity of
#' interest in contour finding and calibration problems.
#'
#' @param model a \code{homGP} or \code{hetGP} model, as returned by
#'   \code{\link[hetGP]{mleHomGP}} or \code{\link[hetGP]{mleHetGP}}.
#' @param thres numeric scalar, the target output level whose crossing location
#'   is sought (on the same scale as the responses used to fit \code{model}).
#' @param grid01 numeric vector of input locations at which to evaluate the
#'   posterior, in increasing order. Must lie within the model's input domain
#'   (typically \eqn{[0, 1]}). Grid resolution sets the interpolation accuracy
#'   of the crossing estimate.
#' @param n_sim integer, the number of posterior sample paths to draw. Larger
#'   values give more stable quantiles at higher cost. Defaults to 500.
#' @param probs numeric vector of length two, the lower and upper probabilities
#'   for the returned credible interval. Defaults to \code{c(0.05, 0.95)}.
#'
#' @details
#' The method draws \code{n_sim} realisations of the latent function jointly
#' over \code{grid01} from the GP posterior, using the full predictive
#' covariance (obtained by calling \code{predict} with \code{xprime} set to the
#' grid). The joint covariance is essential: sampling each grid point
#' independently would yield non-smooth paths that cross \code{thres} spuriously.
#'
#' For each sampled path, the first crossing of \code{thres} is located by
#' detecting a sign change in \code{f - thres} and interpolating linearly within
#' the bracketing grid interval, giving a sub-grid-resolution estimate. The
#' empirical quantiles of these crossing locations across all paths form the
#' credible interval.
#'
#' Paths that never cross \code{thres} contribute \code{NA} and are excluded from
#' the quantiles. The proportion of paths that do cross is returned as
#' \code{frac_crossing} and should be inspected: values well below 1 indicate the
#' target is only marginally reachable given the current design, so the interval
#' is computed from a non-representative subset and should not be trusted as a
#' convergence signal.
#'
#' A small jitter (\code{model$eps}) is added to the covariance diagonal to
#' ensure the Cholesky factorisation underlying the sampling succeeds. On
#' near-deterministic regions of the response (where the fitted noise is close to
#' zero) this jitter dominates the local variance; the crossing of interest
#' should therefore lie in a region with genuine posterior spread for the
#' interval to be meaningful.
#'
#' @section Assumptions:
#' The first crossing is taken as \emph{the} crossing, which assumes a monotone
#' or single-crossing response over \code{grid01}. For responses that cross
#' \code{thres} more than once, only the lowest-input crossing is reported and
#' subsequent ones are ignored.
#'
#' @return A named numeric vector of length three: the two quantiles of the
#'   crossing location (named by \code{probs}, e.g. \code{"5\%"} and
#'   \code{"95\%"}), on the scale of \code{grid01}; and \code{frac_crossing},
#'   the proportion of sampled paths that crossed \code{thres}.
#'
#' @seealso \code{\link[hetGP]{crit_optim}} and \code{\link[hetGP]{crit_cSUR}}
#'   for the acquisition criteria that place designs near such a contour;
#'   \code{\link[hetGP]{predict.hetGP}} for the underlying predictions.
#'
#' @references
#' Binois, M., Gramacy, R. B. (2021). hetGP: Heteroskedastic Gaussian Process
#' Modeling and Sequential Design in R. \emph{Journal of Statistical Software},
#' 98(13), 1--44. \doi{10.18637/jss.v098.i13}.
#'
#' @examples
#' \dontrun{
#' library(hetGP)
#' X <- matrix(seq(0, 1, length.out = 20), ncol = 1)
#' Z <- 3 * pmax(0, X - 0.3) + rnorm(20, sd = 0.05)
#' model <- mleHomGP(X, Z, covtype = "Matern5_2")
#'
#' grid <- seq(0, 1, length.out = 501)
#' ci <- contour_ci(model, thres = 1, grid01 = grid)
#' ci # 5%, 95%, frac_crossing
#'
#' # convergence check: narrow interval AND target well bracketed
#' converged <- (diff(ci[1:2]) < 0.02) && (ci["frac_crossing"] > 0.95)
#' }
#'
#' @importFrom MASS mvrnorm
#' @importFrom stats predict quantile
#' @export
contour_ci <- function(
  model,
  thres,
  grid01,
  n_sim = 500,
  probs = c(0.05, 0.95)
) {
  G <- matrix(grid01, ncol = 1)
  p <- predict(model, G, xprime = G)

  Sig <- p$cov + diag(model$eps, length(grid01))
  paths <- MASS::mvrnorm(n_sim, mu = p$mean, Sigma = Sig)

  cross <- apply(paths, 1, function(f) {
    i <- which(diff(sign(f - thres)) != 0)
    if (!length(i)) {
      return(NA_real_)
    }
    i <- i[1]
    grid01[i] + (thres - f[i]) / (f[i + 1] - f[i]) * (grid01[i + 1] - grid01[i])
  })

  c(
    stats::quantile(cross, probs, na.rm = TRUE),
    frac_crossing = mean(!is.na(cross))
  )
}

plot_gp <- function(mod, val, par_range) {
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
    # geom_vline(xintercept = 0.203) +
    geom_ribbon(aes(ymin = y_min, ymax = y_max), alpha = 0.1) +
    geom_point(data = d_vals, aes(x = x, y = y), alpha = 0.5) +
    geom_hline(yintercept = tar)
}

get_new_gp_prop <- function(mod, n_batch) {
  new_p <- numeric(n_batch)
  for (i in seq_len(n_batch)) {
    opt <- hetGP::crit_optim(
      mod,
      crit = "crit_cSUR",
      thres = tar, # + rnorm(1, 0, 0.1),
      h = 0,
      control = list(multi.start = 10, maxit = 100)
    )
    new_p[i] <- opt$par
    xn <- matrix(opt$par, nrow = 1)
    mod <- update(mod, Xnew = xn, Znew = predict(mod, xn)$mean, maxit = 0)
  }
  new_p
}
