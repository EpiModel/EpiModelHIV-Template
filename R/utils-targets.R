library("dplyr")
library("EpiModel")

targets <- c(
  # 1st calibration set (all independant)
  cc.dx.B                                 = 0.847,
  cc.dx.H                                 = 0.818,
  cc.dx.W                                 = 0.873,
  cc.linked1m.B                           = 0.829,
  cc.linked1m.H                           = 0.898,
  cc.linked1m.W                           = 0.890,
  # CombPrev appendix 8.2.2
  # 2nd calibration set (all independant)
  cc.vsupp.B                              = 0.602,
  cc.vsupp.H                              = 0.620,
  cc.vsupp.W                              = 0.710,
  # STIs
  ir100.gc                                = 12.81,
  ir100.ct                                = 14.59,
  # 3rd calibration set
  i.prev.dx.B                             = 0.33,
  i.prev.dx.H                             = 0.127,
  i.prev.dx.W                             = 0.084,
  i.prev.dx                               = 0.17, # not used yet but maybe?
  cc.prep.ind.B                           = 0.387,
  cc.prep.ind.H                           = 0.379,
  cc.prep.ind.W                           = 0.407,
  cc.prep.ind                             = 0.402,
  cc.prep.B                               = 0.206,
  cc.prep.H                               = 0.237,
  cc.prep.W                               = 0.332,
  cc.prep                                 = 0.203,
  prep_prop_ret1y                         = 0.56, # DOI: 10.1002/jia2.25252
  prep_prop_ret2y                         = 0.41,
  disease.mr100                           = 0.273
)

# function to calculate the calibration target
mutate_calibration_targets <- function(d) {
  d %>% mutate(
    cc.dx.B         = i_dx__B / i__B,
    cc.dx.H         = i_dx__H / i__H,
    cc.dx.W         = i_dx__W / i__W,
    cc.linked1m.B   = linked1m__B / i_dx__B,
    cc.linked1m.H   = linked1m__H / i_dx__H,
    cc.linked1m.W   = linked1m__W / i_dx__W,
    cc.vsupp.B      = i_sup__B / i_dx__B,
    cc.vsupp.H      = i_sup__H / i_dx__H,
    cc.vsupp.W      = i_sup__W / i_dx__W,
    gc_s            = gc_s__B + gc_s__H + gc_s__W,
    ir100.gc        = incid.gc / gc_s * 5200,
    ct_s            = ct_s__B + ct_s__H + ct_s__W,
    ir100.ct        = incid.ct / ct_s * 5200,
    i.prev.dx.B     = i_dx__B / n__B,
    i.prev.dx.H     = i_dx__H / n__H,
    i.prev.dx.W     = i_dx__W / n__W,
    cc.prep.B       = s_prep__B / s_prep_elig__B,
    cc.prep.H       = s_prep__H / s_prep_elig__H,
    cc.prep.W       = s_prep__W / s_prep_elig__W,
    prep_users      = s_prep__B + s_prep__H + s_prep__W,
    prep_elig       = s_prep_elig__B + s_prep_elig__H + s_prep_elig__W,
    cc.prep         = prep_users / prep_elig,
    prep_prop_ret1y = prep_ret1y / lag(prep_startat, 52),
    prep_prop_ret2y = prep_ret2y / lag(prep_startat, 104)
  )
}

process_one_calibration <- function(file_name, nsteps = 52) {
  # keep only the file name without extension and split around `__`
  name_elts <- fs::path_file(file_name) %>%
    fs::path_ext_remove() %>%
    strsplit(split = "__")

  scenario_name <- name_elts[[1]][2]
  batch_num <- as.numeric(name_elts[[1]][3])

  d <- as_tibble(readRDS(file_name))
  d <- d %>%
    filter(time >= max(time) - (nsteps + 52 * 3)) %>% # margin for prep_ret2y
    mutate_calibration_targets() %>%
    filter(time >= max(time) - nsteps) %>%
    select(c(sim, any_of(names(targets)))) %>%
    group_by(sim) %>%
    summarise(across(
      everything(),
      ~ mean(.x, na.rm = TRUE)
    )) %>%
    mutate(
      scenario_name = scenario_name,
      batch = batch_num
    )

  return(d)
}

# required trackers for the calibration step
source("R/utils-epi_trackers.R")

# Named list of trackers required for computing the calibration targets
# the `epi_` functions are function factories (see https://adv-r.hadley.nz/function-factories.html?q=factory#function-factories). They take as argument the `race`
# set to include in the calculation (1, 2, 3 or 1:3).
# They return a "tracker function". See the "Working with Custom Attributes and
# Summary Statistics in EpiModel" vignette from EpiModel
calibration_trackers <- list(
  n__B           = epi_n(1),
  n__H           = epi_n(2),
  n__W           = epi_n(3),
  i__B           = epi_i(1),
  i__H           = epi_i(2),
  i__W           = epi_i(3),
  i_dx__B        = epi_i_dx(1),
  i_dx__H        = epi_i_dx(2),
  i_dx__W        = epi_i_dx(3),
  i_sup__B       = epi_i_sup(1),
  i_sup__H       = epi_i_sup(2),
  i_sup__W       = epi_i_sup(3),
  linked1m__B    = epi_linked_time(4)(1),
  linked1m__H    = epi_linked_time(4)(2),
  linked1m__W    = epi_linked_time(4)(3),
  gc_s__B        = epi_gc_s(c(0, 1))(1), # gc susceptible HIV+ and -
  gc_s__H        = epi_gc_s(c(0, 1))(2),
  gc_s__W        = epi_gc_s(c(0, 1))(3),
  ct_s__B        = epi_ct_s(c(0, 1))(1),
  ct_s__H        = epi_ct_s(c(0, 1))(2),
  ct_s__W        = epi_ct_s(c(0, 1))(3),
  s_prep__B      = epi_s_prep(1),
  s_prep__H      = epi_s_prep(2),
  s_prep__W      = epi_s_prep(3),
  s_prep_elig__B = epi_s_prep_elig(1),
  s_prep_elig__H = epi_s_prep_elig(2),
  s_prep_elig__W = epi_s_prep_elig(3),
  prep_startat   = epi_prep_ret(0)(1:3),  # n starting at `at`
  prep_ret1y     = epi_prep_ret(52)(1:3), # n starting at `at - 52`
  prep_ret2y     = epi_prep_ret(104)(1:3) # n starting at `at - 104`
)

