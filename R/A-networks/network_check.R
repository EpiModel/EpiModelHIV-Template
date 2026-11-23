## Network check: do the fitted networks reproduce their target statistics?
##
## This script should not be run directly. But `sourced` by `3-check.R`, and by
## anything that needs `assert_network_check()` before it runs `netsim`.
##
## The gate between the network fits and the epidemic calibration. For each of
## the three layers it compares every target statistic of the fit with what
## the fitted model simulates, from the diagnostics `2-diagnostics.R` saved:
##
##   static    draws from the cross-sectional model, all three layers. A miss
##             here is a problem with the fit itself.
##   dynamic   the last part of the tergm simulation, main and casual layers,
##             at the sampling every netsim run uses (`control_tergm_sim()`).
##             The one-off layer is drawn exactly in netsim, so its static
##             check is its whole check. A statistic that passes the static
##             check and misses here is under-sampled by tergm at that setting,
##             or the dissolution approximation is off.
##   duration  mean partnership duration by age group, from the same dynamic
##             simulation.
##
## A statistic passes if its simulated mean is within `network_check_tol` of
## the target, relative, or within one standard deviation of the statistic
## across the simulated networks, whichever is wider. The second rule only
## bites on small counts (a one-off layer with 40 Black-Black partnerships a
## week varies by more than 5 percent from one draw to the next), and a mean
## inside that variation is not a miss worth refitting for. A target of zero
## must be simulated as zero.
##
## The attributes are static in these simulations, as in any `netdx`. What
## aging, arrivals and departures do to the networks in the full model is not
## tested here; that belongs to the netsim work this check comes before.

# Relative tolerance on every target statistic and duration.
network_check_tol <- 0.05

# The dynamic check averages the last part of the simulation, this share of
# its steps. The simulation starts from a cross-sectional draw at the targets,
# so an under-sampled statistic decays from there over about one partnership
# duration, and an average over the whole run would dilute the miss.
network_check_window <- 0.5

#' One row per target statistic: its target, its simulated mean and whether
#' the mean is within tolerance.
#'
#' @param sims matrix of simulated statistics, one row per simulated network
#' @param targets named vector of target statistics
network_check_rows <- function(sims, targets, layer, check, tol) {
  # A homophily term fit with one parameter (`diff = FALSE`) is the sum of the
  # per-level counts, when the diagnostics monitor it by level (`diff = TRUE`)
  for (name in setdiff(names(targets), colnames(sims))) {
    by_level <- startsWith(colnames(sims), paste0(name, "."))
    if (startsWith(name, "nodematch.") && any(by_level)) {
      sims <- cbind(sims, rowSums(sims[, by_level, drop = FALSE]))
      colnames(sims)[ncol(sims)] <- name
    }
  }
  missing <- setdiff(names(targets), colnames(sims))
  if (length(missing) > 0) {
    stop(
      "The ",
      layer,
      " diagnostics do not monitor these target statistics: ",
      paste(missing, collapse = ", "),
      ". Add them to the diagnostic ",
      "formula in `diag_",
      layer,
      ".R`."
    )
  }
  sims <- sims[, names(targets), drop = FALSE]
  simulated <- colMeans(sims)
  sd <- apply(sims, 2, stats::sd)
  limit <- ifelse(targets == 0, 0, pmax(tol * abs(targets), sd))
  data.frame(
    layer = layer,
    check = check,
    statistic = names(targets),
    target = unname(targets),
    simulated = unname(simulated),
    ratio = unname(ifelse(targets == 0, NA, simulated / targets)),
    sd = unname(sd),
    limit = unname(limit),
    pass = unname(abs(simulated - targets) <= limit)
  )
}

#' The duration rows of a dynamic diagnostic: mean age of the partnerships
#' present, by dissolution term, against the durations the fit was given.
network_check_durations <- function(dynamic, late, layer, tol) {
  targets <- dynamic$coef.diss$duration
  ages <- dynamic$pages_imptd[late, , , drop = FALSE]
  simulated <- apply(ages, 2, mean, na.rm = TRUE)
  sd <- apply(ages, 2, stats::sd, na.rm = TRUE)
  limit <- pmax(tol * targets, sd)
  data.frame(
    layer = layer,
    check = "duration",
    statistic = rownames(dynamic$stats.table.duration),
    target = targets,
    simulated = simulated,
    ratio = simulated / targets,
    sd = sd,
    limit = limit,
    pass = abs(simulated - targets) <= limit
  )
}

#' Check the three fitted layers against their targets.
#'
#' @param est_path the `netest` file of the fits
#' @param diag_dir where `2-diagnostics.R` saved their diagnostics
#' @param context "local" or "hpc"
#' @param proposals the tergm proposals per step the simulations use
#'        (`tergm_proposals`). The dynamic diagnostics must have run at it.
#'
#' @return a list: `table` (one row per statistic and check), `problems`
#'         (reasons the check cannot be trusted, such as diagnostics of
#'         another fit), `pass`, and what the check was run on.
network_check <- function(
  est_path,
  diag_dir,
  context,
  proposals,
  tol = network_check_tol,
  window = network_check_window
) {
  est <- readRDS(est_path)
  layers <- c(main = "fit_main", casl = "fit_casl", ooff = "fit_ooff")
  rows <- list()
  problems <- character()

  for (layer in names(layers)) {
    fit <- est[[layers[[layer]]]]
    dx_path <- fs::path(diag_dir, paste0("netdx-", layer, "-", context, ".rds"))
    if (!file.exists(dx_path)) {
      problems <- c(problems, paste0(layer, ": no diagnostics at ", dx_path))
      next
    }
    dx <- readRDS(dx_path)

    # A failed estimation leaves the previous diagnostics in place, and files
    # copied from the HPC lose their dates, so match on the coefficients.
    if (!isTRUE(all.equal(dx$static$coef.form, fit$coef.form))) {
      problems <- c(
        problems,
        paste0(
          layer,
          ": the diagnostics are of another fit. Rerun `2-diagnostics.R`."
        )
      )
      next
    }

    targets <- stats::setNames(fit$target.stats, fit$target.stats.names)
    rows[[paste(layer, "static")]] <- network_check_rows(
      do.call(rbind, dx$static$stats),
      targets,
      layer,
      "static",
      tol
    )

    # A layer whose partnerships last one step is drawn exactly in netsim
    if (fit$coef.diss$duration[1] <= 1) {
      next
    }

    if (is.null(dx$dynamic)) {
      problems <- c(problems, paste0(layer, ": no dynamic diagnostics"))
      next
    }
    ran_at <- dx$tergm_proposals
    if (is.null(ran_at) || ran_at != proposals) {
      problems <- c(
        problems,
        paste0(
          layer,
          ": the dynamic diagnostics ran at ",
          if (is.null(ran_at)) {
            "an unrecorded number of"
          } else {
            format(ran_at, big.mark = ",", scientific = FALSE)
          },
          " tergm proposals per step and the simulations use ",
          format(proposals, big.mark = ",", scientific = FALSE),
          ". Rerun `2-diagnostics.R`."
        )
      )
    }
    nsteps <- dx$dynamic$nsteps
    late <- seq(floor(nsteps * (1 - window)) + 1, nsteps)
    sims <- do.call(
      rbind,
      lapply(dx$dynamic$stats, function(sim) sim[late, , drop = FALSE])
    )
    rows[[paste(layer, "dynamic")]] <- network_check_rows(
      sims,
      targets,
      layer,
      "dynamic",
      tol
    )
    rows[[paste(layer, "duration")]] <- network_check_durations(
      dx$dynamic,
      late,
      layer,
      tol
    )
  }

  table <- do.call(rbind, rows)
  rownames(table) <- NULL
  list(
    table = table,
    problems = problems,
    pass = length(problems) == 0 && all(table$pass),
    netest_md5 = unname(tools::md5sum(est_path)),
    tergm_proposals = proposals,
    tol = tol,
    window = window,
    date = Sys.Date()
  )
}

#' Print a check: one line per layer and check, then every miss.
print_network_check <- function(check) {
  table <- check$table
  if (!is.null(table)) {
    off <- abs(table$ratio - 1)
    summary <- do.call(
      rbind,
      lapply(
        split(
          seq_len(nrow(table)),
          paste(table$layer, table$check),
          drop = TRUE
        ),
        function(i) {
          data.frame(
            layer = table$layer[i[1]],
            check = table$check[i[1]],
            statistics = length(i),
            passed = sum(table$pass[i]),
            largest.miss = if (all(is.na(off[i]))) {
              ""
            } else {
              worst <- i[which.max(off[i])]
              sprintf(
                "%+.1f%% %s",
                100 * (table$ratio[worst] - 1),
                table$statistic[worst]
              )
            }
          )
        }
      )
    )
    summary <- summary[
      order(
        match(summary$layer, c("main", "casl", "ooff")),
        match(summary$check, c("static", "dynamic", "duration"))
      ),
    ]
    print(summary, row.names = FALSE)

    misses <- table[!table$pass, ]
    if (nrow(misses) > 0) {
      message("\nOutside tolerance:")
      numeric <- c("target", "simulated", "ratio", "sd", "limit")
      misses[numeric] <- lapply(misses[numeric], signif, digits = 4)
      print(
        misses[, c(
          "layer",
          "check",
          "statistic",
          "target",
          "simulated",
          "ratio",
          "limit"
        )],
        row.names = FALSE
      )
      both <- merge(
        misses[misses$check == "dynamic", c("layer", "statistic")],
        table[table$check == "static" & table$pass, c("layer", "statistic")]
      )
      if (nrow(both) > 0) {
        message(
          "\n",
          nrow(both),
          " of them pass the static check and miss only in ",
          "the dynamic simulation:\n  tergm is under-sampling at the ",
          "setting the diagnostics ran at (`tergm_proposals` in\n  ",
          "R/shared_variables.R), or the dissolution approximation is off ",
          "for those terms."
        )
      }
    }
  }
  if (length(check$problems) > 0) {
    message(
      "\nThe check cannot be trusted:\n",
      paste0("  ", check$problems, collapse = "\n")
    )
  }
  invisible(check)
}

#' Stop unless the fits at `est_path` have passed the network check, at the
#' tergm sampling the simulations are about to use.
#'
#' The check is matched to the fits by the checksum of the `netest` file, so a
#' refit, or a check copied beside the wrong estimates, fails here.
assert_network_check <- function(est_path, check_path, proposals) {
  redo <- "Run `R/A-networks/3-check.R` for this city and context."
  if (!file.exists(check_path)) {
    stop(
      "These network fits have not been checked against their targets: ",
      "no `",
      check_path,
      "`. ",
      redo
    )
  }
  check <- readRDS(check_path)
  if (!identical(check$netest_md5, unname(tools::md5sum(est_path)))) {
    stop(
      "`",
      check_path,
      "` is the check of another set of fits than `",
      est_path,
      "`. ",
      redo
    )
  }
  if (!identical(as.numeric(check$tergm_proposals), as.numeric(proposals))) {
    stop(
      "The network check ran at ",
      format(check$tergm_proposals, big.mark = ",", scientific = FALSE),
      " tergm proposals per step and the simulations use ",
      format(proposals, big.mark = ",", scientific = FALSE),
      ". Rerun `2-diagnostics.R`, then `3-check.R`."
    )
  }
  if (!isTRUE(check$pass)) {
    stop(
      "The network fits at `",
      est_path,
      "` did not pass their check (",
      sum(!check$table$pass),
      " statistics outside tolerance, ",
      length(check$problems),
      " other problems). See `",
      fs::path_ext_set(check_path, "csv"),
      "`."
    )
  }
  invisible(TRUE)
}
