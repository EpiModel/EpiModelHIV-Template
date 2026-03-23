# Scratchpad for interactive testing before integration in a script
#
# TODO: test over way longer. Maybe on HPC to check for validity
#
#
library(dplyr)
source("R/shared_variables.R", local = TRUE)
pkgload::load_all("../../EpiModel.git/main/")
pkgload::load_all("../../EpiModelHIV-p.git/main/") # use branch `main_plus_epi`
# pkgload::load_all("../../EpiModelHIV-p.git/reworks/")
# library(EpiModelHIV)
context <- "local"
source("R/netsim_settings.R", local = TRUE)
est <- readRDS(path_to_est)
control <- control_msm(
  nsteps = 70 * year_steps,
  nsims = 10,
  ncores = 1,
  future.use.plan = future::tweak("multicore", workers = 10),
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
# $ hiv.inf       <dbl> 3210.254 <dbl> 3043.054
# $ hiv.dx        <dbl> 2536.112 <dbl> 2665.254
# $ hiv.tx        <dbl> 1596.388 <dbl> 1658.358
# $ hiv.supp      <dbl> 1568.265 <dbl> 1630.463
# $ gono.uret.inf <dbl> 230.4212 <dbl> 229.0673
# $ gono.rect.inf <dbl> 407.2423 <dbl> 402.6635
# $ chla.uret.inf <dbl> 285.9308 <dbl> 284.9865
# $ chla.rect.inf <dbl> 520.1577 <dbl> 514.25
# $ syph.inf      <dbl> 610.8365 <dbl> 649.9135
# $ prep          <dbl> 910.075  <dbl> 1265.604
# $ prep.incid    <dbl> 14.92115 <dbl> 20.98269
# $ prep.indic    <dbl> 3455.383 <dbl> 4829.946
# $ num           <dbl> 9914.233 <dbl> 10009.3
# $ n_acts        <dbl> 5524.715 <dbl> 5676.508
# $ n_cond        <dbl> 1833.519 <dbl> 1826.629
# $ n_cond_acts   <dbl> 5524.715 <dbl> 5676.508
# $ n_ins         <dbl> 2796.125 <dbl> 2717.379
# $ dbg_mdur      <dbl> 175.2017 <dbl> 176.7658
# $ dbg_rc        <dbl> 3.36796  <dbl> 3.218675
# $ dbg_ac        <dbl> 77.83458 <dbl> 78.40062
# $ dbg_hc        <dbl> 0.129269 <dbl> 0.1397717
# $ dbg_pa        <dbl> 0.237066 <dbl> 0.3018283
# OLD
# $ hiv.inf       <dbl> 3043.054
# $ hiv.dx        <dbl> 2665.254
# $ hiv.tx        <dbl> 1658.358
# $ hiv.supp      <dbl> 1630.463
# $ gono.uret.inf <dbl> 229.0673
# $ gono.rect.inf <dbl> 402.6635
# $ chla.uret.inf <dbl> 284.9865
# $ chla.rect.inf <dbl> 514.25
# $ syph.inf      <dbl> 649.9135
# $ prep          <dbl> 1265.604
# $ prep.incid    <dbl> 20.98269
# $ prep.indic    <dbl> 4829.946
# $ num           <dbl> 10009.3
# $ n_acts        <dbl> 5676.508
# $ n_cond        <dbl> 1826.629
# $ n_cond_acts   <dbl> 5676.508
# $ n_ins         <dbl> 2717.379
# $ dbg_mdur      <dbl> 176.7658
# $ dbg_rc        <dbl> 3.218675
# $ dbg_ac        <dbl> 78.40062
# $ dbg_hc        <dbl> 0.1397717
# $ dbg_pa        <dbl> 0.3018283

lobstr::obj_size(param)
lobstr::obj_size(control)
lobstr::obj_size(init)
lapply(control, lobstr::obj_size)

lapply(est[[3]]$newnetwork, lobstr::obj_size)
