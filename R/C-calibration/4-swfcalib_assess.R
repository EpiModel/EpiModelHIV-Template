## 3. swfcalib Assessment
##
## interactive script to evaluate why an swfcalib process did not returned the
## expected results. It creates the assessment report and interactively look
## into the `results.rds` object found in the calibration folder.

# Restart R before running this script (Ctrl_Shift_F10 / Cmd_Shift_0)

# Render calib assessment ------------------------------------------------------
source("R/shared_variables.R", local = TRUE)
swfcalib::render_assessment(fs::path(swfcalib_dir, "assessments.rds"))

# Setup ------------------------------------------------------------------------
library(dplyr)
library(tidyr)
library(ggplot2)
theme_set(theme_light())
source("R/shared_variables.R", local = TRUE)
source("R/C-calibration/z-context.R", local = TRUE)

results <- readRDS(fs::path(swfcalib_dir, "results.rds"))

results |>
  filter(.iteration == max(.iteration)) |>
  pull(hiv.test.rate_1) |>
  range()

ggplot(results, aes(
  x = hiv.test.rate_3,
  y = cc.dx.W,
  col = as.factor(.iteration)
)) +
geom_point() +
geom_hline(yintercept = 0.862) +
geom_vline(xintercept = 0.0013)

filter(results, .iteration > 1) |>
ggplot( aes(
  x = syph.prob,
  y = ir100.syph,
  col = as.factor(.iteration)
)) +
geom_point()


d_eval <- results[, c('ir100.syph', 'syph.prob')]
d_eval$ir100.syph <- ifelse(d_eval$ir100.syph == 0, -Inf, d_eval$ir100.syph)


results <- readRDS(fs::path(swfcalib_dir, "results.rds"))
# results$ir100.syph <- ifelse(results$ir100.syph == 0, Inf, results$ir100.syph)
results <- results[results$.iteration < 2, ]
results <- results[results$ir100.syph > 0, ]
job = list(
  targets = "ir100.syph",
  targets_val = 1,
  params = c("syph.prob")
)
n_new = 256
retain_prop = 0.3
thresholds = 0.2


make_proposer_se_range <- function(n_new, retain_prop = 0.2) {
  force(n_new)
  force(retain_prop)
  function(calib_object, job, results) {
    p_ranges <- list()
    values <- results[job$targets]
    params <- results[job$params]

    params[[".SE_score"]] <- 0
    for (i in seq_along(job$targets)) {
      t <- job$targets_val[i]
      vs <- values[[i]]
      params[[".SE_score"]] <- params[[".SE_score"]] + (vs - t)^2
    }

    params <- dplyr::arrange(params, .data$.SE_score)
    params <- dplyr::select(params, - .data$.SE_score)
    params <- head(params, ceiling(n_new * retain_prop))

    for (i in seq_along(job$targets)) {
      p_ranges[[i]] <- range(params[[i]])
    }

    proposals <- lhs::randomLHS(n_new, length(job$params))
    for (i in seq_along(job$params)) {
      spread <- p_ranges[[i]][2] - p_ranges[[i]][1]
      rmin <- p_ranges[[i]][1]
      proposals[, i] <- proposals[, i] * spread + rmin
    }
    colnames(proposals) <- job$params
    dplyr::as_tibble(proposals)
  }
}








d_eval <- results[results$ir100.syph > 0, c('ir100.syph', 'syph.prob')]
mod <- lm(syph.prob ~ ir100.syph, data = d_eval)
predict(mod, newdata = data.frame(ir100.syph = 2))





make_shrink_proposer <- function(n_new, shrink = 2) {
  force(n_new)
  force(shrink)
  function(calib_object, job, results) {
    centers <- swfcalib::load_sideload(calib_object, job)$centers
    if (is.null(centers)) {
      stop("No centers were provided for shrinkage, abort!")
    }

    outs <- list()
    for (i in seq_along(job$params)) {
      tar_range <- range(
        results[[job$params[i]]][
          results[[".iteration"]] == max(results[[".iteration"]])
        ]
      )
      spread <- (tar_range[2] - tar_range[1]) / shrink / 2

      proposals <- seq(
        max(centers[i] - spread, tar_range[1]),
        min(centers[i] + spread, tar_range[2]),
        length.out = n_new
      )

      proposals <- sample(proposals)

      out <- list(proposals)
      names(out) <- job$params[i]
      outs[[i]] <- dplyr::as_tibble(out)
    }
    dplyr::bind_cols(outs)
  }
}


# raw_res = results

results = raw_res[raw_res$.iteration <= 2, ]
results$ir100.syph <- ifelse(results$ir100.syph == 0, NA, results$ir100.syph)

determ_poly_end <- function(threshold, poly_n = 3) {
  force(threshold)
  force(poly_n)
  function(calib_object, job, results) {
    mscale <- function(x, val) (x - mean(val)) / sd(val)
    munscale <- function(x, val) x * sd(val) + mean(val)

    values <- c()
    params <- c()
    targets <- job$targets_val

    for (i in seq_along(job$targets)) {
      values <- c(values, results[[ job$targets[i] ]])
      params <- c(params, results[[ job$params[i] ]])
    }

    complete_rows <- vctrs::vec_detect_complete(values)
    values <- values[complete_rows]
    params <- params[complete_rows]

    s_v <- mscale(values, values)
    s_t <- mscale(targets, values)
    s_p <- mscale(params, params)

    mod <- lm(s_v ~ poly(s_p, poly_n))
    loss_fun <- function(par, t)  abs(predict(mod, data.frame(s_p = par)) - t)
    s_newp <- vapply(
      s_t,
      function(t) optimize(interval = range(s_p), f = loss_fun, t = t)$minimum,
      numeric(1)
    )
    s_newv <- predict(mod, data.frame(s_p = s_newp))
    newp <- munscale(s_newp, params)

    oldp <- swfcalib::load_sideload(calib_object, job)$centers
    swfcalib::save_sideload(calib_object, job, list(centers = newp))

    if (is.null(oldp)) return(NULL)

    s_oldp <- mscale(oldp, params)
    s_oldv <- predict(mod, data.frame(s_p = s_oldp))

    newv <- munscale(s_newv, values)
    oldv <- munscale(s_oldv, values)

    if (all(abs(oldv - newv) < threshold & abs(newv - targets) < threshold)) {
      result <- as.list(newp)
      names(result) <- job$params
      return(dplyr::as_tibble(result))
    } else {
      return(NULL)
    }
  }
}
