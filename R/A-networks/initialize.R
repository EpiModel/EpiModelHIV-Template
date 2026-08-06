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
  epistats <- build_epistats(
    geog.lvl = "city",
    geog.cat = "Atlanta",
    init.hiv.prev = c(0.33, 0.137, 0.084), # by race: Black, Hispanic, White
    race = TRUE,
    time.unit = time_unit
  )

  netparams <- build_netparams(
    epistats = epistats,
    smooth.main.dur = TRUE
  )

  # Race composition of the modeled population, ordered Black, Hispanic,
  # White/Other. Leaving this NULL falls back to `ARTnetData::race.dist`, whose
  # `city` rows are MUNICIPALITY figures rather than metro ones: its "Atlanta"
  # row is 0.515 / 0.046 / 0.439, which is the city proper, while men aged 15-64
  # across the four-county EHE metro are 0.366 / 0.166 / 0.468. A Hispanic share
  # of 4.6 percent is not attainable for the metro. Set this explicitly for the
  # geography your project actually models.
  #
  # This is not only a calibration input. It sets num.B / num.H / num.W and
  # therefore the in-model denominator of every race-specific target.
  #
  # Reproduce the numbers with, in the EpiModelHIV-p repo:
  #   python3 inst/AHEAD/scripts/02-census-race-distribution.py
  race_prop <- c(0.3662, 0.1661, 0.4678) # <- USER: Black, Hispanic, White/Other

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
