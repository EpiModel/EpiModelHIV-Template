scenario_name <- "empty_scenario"
hpc_context <- TRUE
# scenario_name <- "scenario_2"
# hpc_context <- FALSE

library(EpiModelHIV)
library(dplyr)
source("R/shared_variables.R", local = TRUE)
source("R/C-calibration/z-context.R", local = TRUE)
source("R/C-calibration/utils-restart.R", local = TRUE)
make_restart_pool <- function(sim_obj, time_attrs, sims_num = NULL,
                              keep_steps = 1) {
  if (is.null(sims_num)) {
    sims_num <- seq_len(sim_obj$control$nsims)
  }
  restart_pool <- lapply(
    sims_num,
    EpiModel::make_restart_point,
    sim_obj = sim_obj,
    time_attrs = time_attrs,
    keep_steps = keep_steps
  )
  class(restart_pool) <- c("netsim_restart_pool", class(restart_pool))
  restart_pool
}

# Process ----------------------------------------------------------------------
sim <- readRDS("./data/run/calibration/sim__empty_scenario__1.rds")

attrs_names <- names(EpiModelHIV::get_default_attrs())
time_prefixes <- c(".last$", ".time$")
time_attrs <- Reduce(
  function(a, prefix) c(a, grepv(prefix, attrs_names)),
  time_prefixes,
  init = character(0)
)

restart_point <- make_restart_point(sim, time_attrs, sim_num = 1, keep_steps = 1)

restart_pool <- make_restart_pool(
  sim,
  time_attrs,
  sims_num = NULL,
  keep_steps = 1
)

saveRDS(restart_point, "rp1.rds")
saveRDS(restart_pool, "rpp.rds")

lobstr::obj_size(restart_point)
lapply(restart_point, lobstr::obj_size)
lapply(restart_pool, lobstr::obj_size)

# Better semantics -------------------------------------------------------------
make_restart_point <- function(sim_obj, time_attrs,
                               sims_num = NULL, keep_steps = 1) {
  if (!inherits(sim_obj, c("netsim"))) {
    stop("`sim_obj` must be  an object of class `netsim`")
  }
  required_names <- c(
    "control", "param", "nwparam", "epi", "run", "coef.form", "num.nw"
  )
  missing_names <- setdiff(required_names, names(sim_obj))
  if (length(missing_names) > 0) {
    stop(
      "`sim_obj` is missing the following elements required for",
      " re-initialization: ", paste.and(missing_names)
    )
  }
  # TODO: fix for multi sims
  if (is.null(sims_num)) {
    sims_num <- seq_len(sim_obj$control$nsims)
  }

  if (!sim_obj$control$tergmLite) {
    stop("Only `netsim` object with `tergmLite == TRUE` are supported")
  }

  # Select  the simulation of interest, that renames the selected sim: `sim1`
  x <- get_sims(sim_obj, sims = sims_num)
  n_steps <- x$control$nsteps

  # Keep only the last `keep_steps` rows of each epi
  if (keep_steps < 1 || keep_steps > n_steps) {
    stop("`keep_steps` must be >= 1 and <= `sim_obj$control$nsteps`")
  }
  keep_rows <- (n_steps - keep_steps + 1):n_steps
  x$epi <- lapply(x$epi, function(r) r[keep_rows, , drop = FALSE])

  # If `nwstats` are saved, keep only the last rows
  if (x$control$save.nwstats) {
    x$stats$nwstats$sim1 <- lapply(
      x$stats$nwstats$sim1,
      function(d) d[keep_rows, , drop = FALSE]
    )
  }

  # Time correction
  time_offset <- n_steps - keep_steps
  x$control$start <- 1
  x$control$nsteps <- keep_steps
  time_attrs <- union(c("entrTime", "exitTime"), time_attrs)

  # Per sim --------------------------------------------------------------------
  for (i_run in seq_along(x$run)) {
    run_ls <- x$run[[i_run]]
    # Time attributes - offset so last step is now `keep_steps`
    time_attrs <- union(c("entrTime", "exitTime"), time_attrs)
    missing_attrs <- setdiff(time_attrs, names(run_ls$attr))
    if (length(missing_attrs) > 0) {
      stop(
        "Some time attributes are not present in the attributes list:",
        paste.and(missing_names)
      )
    }
    run_ls$attr[time_attrs] <- lapply(
      run_ls$attr[time_attrs],
      function(v) v - time_offset
    )

    # Fix UIDs
    uid_offset <- min(run_ls$attr$unique_id) - 1
    run_ls$attr$unique_id <- run_ls$attr$unique_id - uid_offset
    run_ls$last_unique_id <- run_ls$last_unique_id - uid_offset


    # Cumulative Edgelist - fix time and UIDs
    run_ls$el_cuml_cur <- lapply(
      run_ls$el_cuml_cur,
      function(el) {
        el$head <- el$head - uid_offset
        el$tail <- el$tail - uid_offset
        el$start <- el$start - time_offset
        el
      }
    )
    # For Historical one - truncate to 1 (only edges in the kept history)
    run_ls$el_cuml_hist <- lapply(
      run_ls$el_cuml_hist,
      function(el) {
        el$head <- el$head - uid_offset
        el$tail <- el$tail - uid_offset
        el$start <- el$start - time_offset
        el$stop <- el$stop - time_offset
        el[el$stop >= 1, , drop = FALSE]
      }
    )

    # the edgelist stores the name of the vertices. We don't use it with
    # `tergmLite` and it takes a lot of space
    run_ls$el <- lapply(run_ls$el, function(x) {
      attr(x, "vnames") <- NULL
      x
    })

    x$run[[i_run]] <- run_ls

    # If transmat was saved, trim it and offset the `at` column
    if (x$control$save.transmat) {
      tsmt <- x$stats$transmat[[i_run]]
      tsmt$at <- tsmt$at - time_offset
      x$stats$transmat$sim1 <- tsmt[tsmt$at > 0, , drop = FALSE]
    }
  }


  # Output ---------------------------------------------------------------------

  x$attr.history <- list()
  x$raw.records <- list()
  return(x)
}

restart_point <- make_restart_point(sim, time_attrs, keep_steps = 1)
saveRDS(restart_point, "rp2.rds")
