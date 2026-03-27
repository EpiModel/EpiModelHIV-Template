# Scratchpad for interactive testing before integration in a script
#
# TODO: test over way longer. Maybe on HPC to check for validity
#
#
library(dplyr)
source("R/shared_variables.R", local = TRUE)
pkgload::load_all("../EMHIV/")
# pkgload::load_all("../mainplus/") # use branch `main_plus_epi`
# library(EpiModelHIV)
context <- "local"
source("R/netsim_settings.R", local = TRUE)
est <- readRDS(path_to_est)
control <- control_msm(
  nsteps = 70 * year_steps,
  nsims = 8,
  ncores = 1,
  future.use.plan = future::tweak("multicore", workers = 8),
  verbose = FALSE
)
start <- Sys.time()
sim <- netsim(est, param, init, control)
print(Sys.time() - start)
d <- as_tibble(sim)
saveRDS(d, "old70.rds")

# d <- readRDS("old70.rds")
d |>
  filter(time > max(time) - 52) |>
  select(
    hiv.inf, hiv.dx, hiv.tx, hiv.supp,
    gono.uret.inf, gono.rect.inf, chla.uret.inf, chla.rect.inf, syph.inf,
    prep, prep.incid, prep.indic, num,
    n_acts, n_cond, n_cond_acts, n_ins,
    starts_with("dbg_")) |>
  summarise(across(everything(), mean)) |> glimpse()

# NEW
# | Epi                | New Value | Old Value |
# | -                  | -         | -         |
# | hiv.inf            | 2757.33   | 2774.70   |
# | hiv.dx             | 2415.61   | 2423.8    |
# | hiv.tx             | 1501.33   | 1516.72   |
# | hiv.supp           | 1475.88   | 1490.94   |
# | gono.uret.inf      | 173.473   | 163.689   |
# | gono.rect.inf      | 303.968   | 288.091   |
# | chla.uret.inf      | 185.75    | 196.437   |
# | chla.rect.inf      | 340.75    | 355.793   |
# | syph.inf           | 608.673   | 642.682   |
# | prep               | 1319.27   | 1302.24   |
# | prep.incid         | 21.625    | 21.5889   |
# | prep.indic         | 5024.92   | 4979.93   |
# | num                | 9989.37   | 9955.40   |
# | n_acts             | 5899.20   | 5844.80   |
# | n_cond             | 1900.39   | 1904.00   |
# | n_cond_acts        | 5899.20   | 5844.80   |
# | n_ins              | 2954.53   | 2785.11   |
# | dbg_mean_dur       | 178.494   | 178.092   |
# | dbg_race_combo     | 3.39289   | 3.24930   |
# | dbg_age_combo      | 78.8683   | 78.6142   |
# | dbg_hiv_concordant | 0.11786   | 0.11769   |
# | dbg_prep_any       | 0.31767   | 0.31566   |

lobstr::obj_size(param)
lobstr::obj_size(control)
lobstr::obj_size(init)
lapply(control, lobstr::obj_size)

lapply(est[[3]]$newnetwork, lobstr::obj_size)
