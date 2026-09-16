# TODO: re-run a bad calib assess with restart pool
# TODO: update merge netsim to use same as netsim saves

hpc_context <- TRUE
pkgload::load_all("../EpiModel/")
library(EpiModelHIV)
library(dplyr)
source("R/shared_variables.R", local = TRUE)
source("R/C-calibration/z-context.R", local = TRUE)

make_restart_point_hiv <- function(sim, sim_num, sim_cost = Inf) {
  attrs_names <- names(EpiModelHIV::get_default_attrs())
  time_prefixes <- c(".last$", ".time$")

  time_attrs <- Reduce(
    function(a, prefix) c(a, grepv(prefix, attrs_names)),
    time_prefixes,
    init = character(0)
  )

  restart_point <- EpiModel::make_restart_point(
    sim,
    time_attrs,
    sim_num,
    keep_steps = 1
  )

  restart_point[["_calibration_cost"]] <- sim_cost
  restart_point
}

# Load files -------------------------------------------------------------------
sim_files <- fs::dir_ls("./data/run/calibration/", regexp = "sim__.*")
sim_res <- lapply(sim_files, readRDS)
# Ensure they all have the same control
sim_res[[1]]$control$save.other <- c(
  "run",
  "coef.form"
)
for (i in 2:length(sim_res)) {
  sim_res[[i]]$control <- sim_res[[1]]$control
}
# Merge sims
sims <- Reduce(merge, sim_res)

# Make the restart pool --------------------------------------------------------
attrs_names <- names(EpiModelHIV::get_default_attrs())
time_prefixes <- c(".last$", ".time$")

time_attrs <- Reduce(
  function(a, prefix) c(a, grepv(prefix, attrs_names)),
  time_prefixes,
  init = character(0)
)

restart_pool <- EpiModel::make_restart_point(
  sims,
  time_attrs,
  sims_num = NULL, # keep all sims
  keep_steps = 1
)
saveRDS(restart_pool, "restart_pool.rds")

str(restart_pool$run, max.level = 1)
