# Scratchpad for interactive testing before integration in a script
#
# TODO: test over way longer. Maybe on HPC to check for validity
#
#
library(dplyr)
source("R/shared_variables.R", local = TRUE)
# pkgload::load_all("../EMHIV/")
pkgload::load_all("../mainplus/") # use branch `main_plus_epi`
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
# $ hiv.inf       <dbl> 2757.339
# $ hiv.dx        <dbl> 2415.615
# $ hiv.tx        <dbl> 1501.332
# $ hiv.supp      <dbl> 1475.885
# $ gono.uret.inf <dbl> 173.4736
# $ gono.rect.inf <dbl> 303.9688
# $ chla.uret.inf <dbl> 185.75
# $ chla.rect.inf <dbl> 340.75
# $ syph.inf      <dbl> 608.6731
# $ prep          <dbl> 1319.274
# $ prep.incid    <dbl> 21.625
# $ prep.indic    <dbl> 5024.925
# $ num           <dbl> 9989.373
# $ n_acts        <dbl> 5899.209
# $ n_cond        <dbl> 1900.392
# $ n_cond_acts   <dbl> 5899.209
# $ n_ins         <dbl> 2954.534
# $ dbg_mdur      <dbl> 178.4946
# $ dbg_rc        <dbl> 3.392896
# $ dbg_ac        <dbl> 78.86831
# $ dbg_hc        <dbl> 0.117868
# $ dbg_pa        <dbl> 0.3176751
# OLD
# $ hiv.inf       <dbl> 2774.707
# $ hiv.dx        <dbl> 2423.8
# $ hiv.tx        <dbl> 1516.728
# $ hiv.supp      <dbl> 1490.947
# $ gono.uret.inf <dbl> 163.6899
# $ gono.rect.inf <dbl> 288.0913
# $ chla.uret.inf <dbl> 196.4375
# $ chla.rect.inf <dbl> 355.7933
# $ syph.inf      <dbl> 642.6827
# $ prep          <dbl> 1302.245
# $ prep.incid    <dbl> 21.58894
# $ prep.indic    <dbl> 4979.933
# $ num           <dbl> 9955.401
# $ n_acts        <dbl> 5844.803
# $ n_cond        <dbl> 1904.002
# $ n_cond_acts   <dbl> 5844.803
# $ n_ins         <dbl> 2785.113
# $ dbg_mdur      <dbl> 178.0929
# $ dbg_rc        <dbl> 3.249304
# $ dbg_ac        <dbl> 78.61422
# $ dbg_hc        <dbl> 0.1176957
# $ dbg_pa        <dbl> 0.3156603

lobstr::obj_size(param)
lobstr::obj_size(control)
lobstr::obj_size(init)
lapply(control, lobstr::obj_size)

lapply(est[[3]]$newnetwork, lobstr::obj_size)
