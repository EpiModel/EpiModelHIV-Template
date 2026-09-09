## 1. Module Development — Post Calibration
##
## Same as B-model_dev/2-debug_modules.R but starting from the calibrated
## restart point (produced by Chapter C). Use this to test module changes
## with calibrated parameters before running intervention scenarios.

# Restart R before running this script
#
# Load the local development version of EpiModelHIV-p
load_local_EpiModelHIV()
library(dplyr)
library(ggplot2)
theme_set(theme_light())

# Setup ------------------------------------------------------------------------
source("R/shared_variables.R", local = TRUE)
hpc_context <- TRUE
source("R/D-interventions/z-context.R", local = TRUE)

# Process ----------------------------------------------------------------------

source("R/netsim_settings.R", local = TRUE)

# Start from the restart point (end of calibration) and run 4 years forward.
# reinit_msm re-initializes the simulation state from the saved restart object.
control <- control_msm(
  start          = restart_time,
  nsteps         = restart_time + year_steps * 4,
  initialize.FUN = reinit_msm,
  # Always ncores = 1 with `load_local_EpiModelHIV()`
  # parallel workers load the installed package, not the dev version.
  ncores         = 1
)

# Inspect the restart point
orig <- readRDS(path_to_restart)
print(orig)
str(orig, max.level = 1)

scenarios_df <- readRDS("./data/run/lhs_scs2.rds")
scenarios_list <- EpiModel::create_scenario_list(scenarios_df)
param <- EpiModel::use_scenario(param, scenarios_list[[1]])

# Epidemic simulation
options(error = recover)
sim <- netsim(orig, param, init, control)




departure_msm <- function(dat, at) {
  ## Input
  # Attributes
  age <- get_attr(dat, "age")
  race <- get_attr(dat, "race")
  hiv.stage <- get_attr(dat, "hiv.stage")
  hiv.tx <- get_attr(dat, "hiv.tx")

  age <- floor(age)

  # Parameters
  aids.on.tx.mort.rate <- get_param(dat, "aids.on.tx.mort.rate")
  aids.off.tx.mort.rate <- get_param(dat, "aids.off.tx.mort.rate")
  netstats <- get_param(dat, "netstats")
  age.sexual.cessation <- get_param(dat, "epistats")[["age.sexual.cessation"]]

  asmr <- netstats[["demog"]][["asmr"]]

  ## AIDS-related deaths
  #1. On tx
  elig_ids <- which(hiv.tx == 1L & hiv.stage == 4L)
  dep_on_ids <- elig_ids[runif(length(elig_ids)) < aids.on.tx.mort.rate]

  #2. Off tx
  elig_ids <- which(hiv.tx == 0L & hiv.stage == 4L)
  dep_off_ids <- elig_ids[runif(length(elig_ids)) < aids.off.tx.mort.rate]

  dep_aids_ids <- c(dep_on_ids, dep_off_ids)

  ## General deaths
  # Take all `posit_ids` (1:n_nodes) and remove the departed from AIDS
  #
  elig_ids <- get_posit_ids(dat)
  if (length(dep_aids_ids) > 0L) {
    # Warning: if `elig_ids` is changed to something else than `1:n_nodes`,
    # the following line will no remove the correct elements.
    # Always do this filtering first
    elig_ids <- elig_ids[-dep_aids_ids]
  }

  rates <- numeric(length(elig_ids))
  races <- sort(unique(race))

  for (i in seq_along(races)) {
    race_subs <- which(race[elig_ids] == races[i])
    rates[race_subs] <- asmr[age[elig_ids[race_subs]], i + 1L]
  }
  dep_gen_ids <- elig_ids[runif(length(rates)) < rates]

  dep_all_ids <- c(dep_gen_ids, dep_aids_ids)

  dat <- depart_nodes(dat, dep_all_ids)

  ## Summary Output
  dat <- set_epi(dat, "departures", at, length(dep_all_ids))
  dat <- set_epi(dat, "departures.AIDS", at, length(dep_aids_ids))

  ## handle sexual cessation age

  # updated age attr with any deleted vertices removed
  age <- get_attr(dat, "age")
  # which nodes are at or above the sexual cessation age?
  nodes_sexual_cessation <- which(age >= age.sexual.cessation)
  # delete any corresponding edges and lasttoggle information
  if (length(nodes_sexual_cessation) > 0L) {
    for (i in seq_len(dat$num.nw)) {
      dat$run$el[[i]] <- delete_edges(dat$run$el[[i]], nodes_sexual_cessation)
      track_duration <- get_network_control(dat, i, "tergmLite.track.duration")
      if (i < dat$num.nw && track_duration) {
        dat$net_attr[[i]]$lasttoggle <-
          delete_edges(dat$net_attr[[i]]$lasttoggle, nodes_sexual_cessation)
      }
    }
  }

  return(dat)



















# Simulation exploration (tidyverse)
d_sim <- as_tibble(sim)

# See all tracked values
glimpse(tail(d_sim))

d_sim <- d_sim |>
  mutate(
    prep_cov = prep / prep.indic
  )

ggplot(d_sim, aes(x = time, y = prep_cov)) +
  geom_line()
