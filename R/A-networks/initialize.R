## Initialize the ARTnet data objects and the networks to be fitted
##
## This script should not be run directly. But `sourced` by `1-estimation.R`

epistats <- build_epistats(
  geog.lvl = "city",
  geog.cat = "Atlanta",
  init.hiv.prev = c(0.33, 0.137, 0.084),
  race = TRUE,
  time.unit = time_unit
)

netparams <- build_netparams(
  epistats = epistats,
  smooth.main.dur = TRUE
)

netstats <- build_netstats(
  epistats,
  netparams,
  expect.mort = 0.000478213,
  network.size = networks_size
)

nw <- EpiModel::network_initialize(netstats$demog$num)
nw_main <- EpiModel::set_vertex_attribute(
  nw,
  names(netstats$attr),
  netstats$attr
)

nw_casl <- nw_main
nw_inst <- nw_main
