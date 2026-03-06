# Scratchpad for interactive testing before integration in a script
#
# TODO: test over way longer. Maybe on HPC to check for validity
#
#
library(dplyr)
source("R/shared_variables.R", local = TRUE)
pkgload::load_all("../../EpiModel.git/main/")
pkgload::load_all("../../EpiModelHIV-p.git/main/")
# pkgload::load_all("../../EpiModelHIV-p.git/reworks/")
# library(EpiModelHIV)
context <- "local"
source("R/netsim_settings.R", local = TRUE)
est <- readRDS(path_to_est)
control <- control_msm(
  nsteps = 10 * year_steps,
  nsims = 10,
  ncores = 1,
  future.use.plan = future::tweak("multicore", workers = 10),
  verbose = FALSE
)
start <- Sys.time()
sim <- netsim(est, param, init, control)
print(Sys.time() - start)
d <- as_tibble(sim)
d |>
  filter(time > max(time) - 52) |>
  select(
    hiv.inf,
    gono.uret.inf, gono.rect.inf, chla.uret.inf, chla.rect.inf, syph.inf,
    n_acts, n_cond, n_cond_acts, n_ins,
    starts_with("dbg_")) |>
  summarise(across(everything(), mean)) |> glimpse()

# NEW
# $ hiv.inf       <dbl> 3028.131
# $ gono.uret.inf <dbl> 292.3577
# $ gono.rect.inf <dbl> 505.3865
# $ chla.uret.inf <dbl> 338.2192
# $ chla.rect.inf <dbl> 608.4788
# $ syph.inf      <dbl> 845.9962
# $ n_acts        <dbl> 5761.25
# $ n_cond        <dbl> 1936.585
# $ n_cond_acts   <dbl> 5761.25
# $ n_ins         <dbl> 2876.988
# $ dbg_mdur      <dbl> 138.2844
# $ dbg_rc        <dbl> 3.246237
# $ dbg_ac        <dbl> 79.49833
# $ dbg_hc        <dbl> 0.1149638
# $ dbg_pa        <dbl> 0.2290845
# OLD
# $ hiv.inf       <dbl> 2937.704
# $ gono.uret.inf <dbl> 263.5942
# $ gono.rect.inf <dbl> 452.1077
# $ chla.uret.inf <dbl> 312.6135
# $ chla.rect.inf <dbl> 551.2731
# $ syph.inf      <dbl> 691.0596
# $ n_acts        <dbl> 5770.825
# $ n_cond        <dbl> 1880.725
# $ n_cond_acts   <dbl> 5770.825
# $ n_ins         <dbl> 2778.296
# $ dbg_mdur      <dbl> 139.3322
# $ dbg_rc        <dbl> 3.092105
# $ dbg_ac        <dbl> 79.42612
# $ dbg_hc        <dbl> 0.1318888
# $ dbg_pa        <dbl> 0.2968773
