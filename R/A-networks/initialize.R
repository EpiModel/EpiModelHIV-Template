## Initialize the ARTnet data objects and the networks to be fitted
##
## This script should not be run directly. But `sourced` by `1-estimation.R`
##
## Creates:
##   epistats  - epidemiological statistics (age, race, HIV prevalence)
##   netstats  - target network statistics derived from ARTnet survey data
##   nw_main   - empty network for main partnership model
##   nw_casl   - empty network for casual partnership model
##   nw_ooff   - empty network for one-off partnership model

if (system.file(package = "ARTnetData") == "") {
  message(
    "=================================================================\n",
    "You are currently using the example population provided by ARTnet\n",
    "Install ARTnetData to get all the features.\n",
    "Follow the instructions at the link below to get access to it.\n",
    "https://github.com/EpiModel/ARTnet/tree/main?tab=readme-ov-file#artnetdata-dependency\n",
    "=================================================================\n"
  )

  epistats <- readRDS(system.file("epistats-example.rds", package = "ARTnet"))
  netstats <- readRDS(system.file("netstats-example.rds", package = "ARTnet"))
} else {
  # The geography, the initial HIV prevalence and the race composition come
  # from the city registry (`city_spec`, set in `R/shared_variables.R`). A value
  # the registry marks provisional is announced here, not used silently.
  if (length(city_spec$provisional) > 0) {
    message(
      "=================================================================\n",
      city_spec$label, ": the registry marks as provisional: ",
      paste(city_spec$provisional, collapse = ", "), ".\n",
      "The networks can be estimated and the model developed with it, but\n",
      "the value itself should not be reported (see `?get_city_spec`).\n",
      "================================================================="
    )
  }

  epistats <- build_epistats(
    geog.lvl = city_spec$geog.lvl,
    geog.cat = city_spec$geog.cat,
    init.hiv.prev = city_spec$init.hiv.prev, # by race: Black, Hispanic, White
    race = TRUE,
    time.unit = time_unit
  )

  netparams <- build_netparams(
    epistats = epistats,
    smooth.main.dur = TRUE
  )

  # Race composition of the modeled population, ordered Black, Hispanic,
  # White/Other, for the counties that define the city. Leaving this NULL falls
  # back to `ARTnetData::race.dist`, whose `city` rows are MUNICIPALITY figures:
  # its "Atlanta" row is 0.515 / 0.046 / 0.439, the city proper, while men aged
  # 15-64 across the four EHE counties are 0.366 / 0.166 / 0.468.
  #
  # This is not only a calibration input. It sets num.B / num.H / num.W and
  # therefore the in-model denominator of every race-specific target.
  race_prop <- city_spec$race.prop

  netstats <- build_netstats(
    epistats,
    netparams,
    expect.mort = 0.000478213,
    network.size = networks_size,
    race.prop = race_prop
  )
}

# Rename "diag.status" -> "hiv.dx" to match EpiModelHIV conventions.
diag_status_pos <- which(names(netstats$attr) == "diag.status")
names(netstats$attr)[diag_status_pos] <- "hiv.dx"

# Build the three network objects. Each starts as an empty network with node
# attributes (age, race, degree, role, etc.) from the ARTnet survey data.
nw <- EpiModel::network_initialize(netstats$demog$num)
nw_main <- EpiModel::set_vertex_attribute(
  nw,
  names(netstats$attr),
  netstats$attr
)

nw_casl <- nw_main
nw_ooff <- nw_main
