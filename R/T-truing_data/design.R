## Waves and proposal designs for the `truing` data campaigns
##
## This script should not be run directly. But `sourced` from the other scripts
## of `R/T-truing_data/`.

# Waves ------------------------------------------------------------------------
# `range`: multipliers of the current value, log-spaced; one pair for every
# parameter of the wave, or named pairs per parameter.
truing_waves <- list(
  list(
    params = paste0("prep.start.rate_", 1:3),
    targets = paste0("cc.prep.", c("B", "H", "W")),
    range = c(0.5, 2)
  ),
  list(
    params = c(paste0("hiv.test.rate_", 1:3), paste0("tx.halt.rate_", 1:3)),
    targets = c(
      paste0("cc.dx.", c("B", "H", "W")),
      paste0("cc.vsupp.", c("B", "H", "W"))
    ),
    range = c(0.5, 2)
  ),
  list(
    params = c("gono.uret.prob", "chla.uret.prob", "syph.prob"),
    targets = c("ir100.gono", "ir100.chla", "ir100.syph"),
    # Uncalibrated defaults: gono 34.6 and chla 84.6 for targets 12.81 and
    # 14.59, syphilis extinct (0 for 2.0)
    range = list(
      gono.uret.prob = c(0.1, 2),
      chla.uret.prob = c(0.1, 2),
      syph.prob = c(1, 4)
    )
  ),
  list(
    params = c(
      paste0("hiv.trans.scale_", 1:3), "aids.off.tx.mort.rate", "a.rate"
    ),
    targets = c(
      paste0("i.prev.dx.", c("B", "H", "W")), "disease.mr100", "num"
    ),
    range = c(0.5, 2)
  )
)

# Every parameter calibrated by a wave
truing_params <- unique(unlist(lapply(truing_waves, `[[`, "params")))

# Current values ---------------------------------------------------------------
# The values carried forward by the campaign (`<truing_dir>/carry.csv`, columns
# `param,value`, written by hand after each wave) over the model defaults.
truing_current_values <- function(params_df, carry_file) {
  defaults <- params_df |>
    dplyr::filter(.data$param %in% truing_params) |>
    dplyr::select("param", "value") |>
    dplyr::mutate(value = as.numeric(.data$value))
  vals <- stats::setNames(defaults$value, defaults$param)
  if (fs::file_exists(carry_file)) {
    carry <- utils::read.csv(carry_file)
    unknown <- setdiff(carry$param, truing_params)
    if (length(unknown) > 0) {
      stop("`", carry_file, "` sets unknown parameters: ",
           paste0(unknown, collapse = ", "))
    }
    vals[carry$param] <- carry$value
  }
  missing <- setdiff(truing_params, names(vals))
  if (length(missing) > 0) {
    stop("No default value for: ", paste0(missing, collapse = ", "))
  }
  vals[truing_params]
}

# The carried values with `params` scaled by `factor` (probabilities capped at 1)
truing_scale_carry <- function(current, params, factor) {
  current[params] <- current[params] * factor
  prob <- grepl("prob", names(current))
  current[prob] <- pmin(current[prob], 1)
  current
}

# Designs ----------------------------------------------------------------------
# A crossed design: every parameter gets `n_points` values over its range (log
# scale), shuffled independently, so that a 1-D slice is clean and the other
# parameters are decorrelated noise.
# - "grid": evenly spaced values (a centred Latin hypercube)
# - "lhs":  one random draw inside each of the `n_points` strata
# Each point is run `n_rep` times.
# `carry`: the name of the carry variant (see `workflow-wave.R`); its
# `carry_factor` scaled the previous wave's carried values in `current`.
make_truing_design <- function(wave, iteration, design, n_points, n_rep,
                               current, ranges = NULL, seed,
                               carry = "root", carry_factor = 1) {
  design <- match.arg(design, c("grid", "lhs"))
  w <- truing_waves[[wave]]
  ranges <- ranges %||% w$range
  set.seed(seed)

  draw <- function(p) {
    rg <- if (is.list(ranges)) ranges[[p]] else ranges
    if (is.null(rg)) stop("No range for `", p, "`")
    u <- if (design == "grid") {
      (seq_len(n_points) - 0.5) / n_points
    } else {
      (seq_len(n_points) - stats::runif(n_points)) / n_points
    }
    x <- current[[p]] * exp(log(rg[1]) + u * (log(rg[2]) - log(rg[1])))
    if (grepl("prob", p)) x <- pmin(x, 1)
    sample(x)
  }
  pts <- lapply(stats::setNames(w$params, w$params), draw) |>
    dplyr::as_tibble()

  # The parameters outside the wave are held at their current values
  fixed <- current[setdiff(names(current), w$params)]
  fixed <- dplyr::as_tibble(as.list(fixed))[rep(1, n_points), ]

  dplyr::bind_cols(pts, fixed) |>
    dplyr::mutate(
      .scenario.id = sprintf("w%d_i%d_%s%s_p%04d", wave, iteration,
                             truing_carry_tag(carry), design,
                             dplyr::row_number()),
      .point = dplyr::row_number(),
      .design = design,
      .carry = carry,
      .carry_factor = carry_factor,
      .wave = wave,
      .iteration = iteration,
      .n_rep = n_rep,
      .at = 1,
      .before = 1
    )
}

# The scenario ids of a carry variant: none for the root, "<carry>_" else
truing_carry_tag <- function(carry) {
  ifelse(carry == "root", "", paste0(carry, "_"))
}

# The scenarios for `EpiModelHPC::step_tmpl_netsim_scenarios()`: only
# `.scenario.id`, `.at` and the parameters (any other column would be read as a
# parameter).
truing_design_to_scenarios <- function(d) {
  d |>
    dplyr::select(".scenario.id", ".at", dplyr::all_of(truing_params)) |>
    EpiModel::create_scenario_list()
}
