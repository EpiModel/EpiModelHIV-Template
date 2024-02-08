library("EpiModelHIV")
library("dplyr")

calib_steps <- 52
scenarios_df <- tibble(
  .scenario.id    = c("scenario_1", "scenario_2"),
  .at             = 1,
  hiv.test.rate_1 = c(0.001, 0.01),
  hiv.test.rate_2 = c(0.001, 0.006),
  hiv.test.rate_3 = c(0.001, 0.006)
)

scenarios_list <- EpiModel::create_scenario_list(scenarios_df)
scenario <- scenarios_list[[2]]

# Settings -------------------------------------------------------------------
source("R/shared_variables.R", local = TRUE)
hpc_context <- TRUE
source("R/Z-calibration/z-context.R", local = TRUE)

# Inputs ---------------------------------------------------------------------
source("R/netsim_settings.R", local = TRUE)

est <- readRDS(path_to_est)
control <- control_msm(
  nsteps              = 52 * 45,
  .tracker.list       = EpiModelHIV::make_calibration_trackers(),
  verbose             = FALSE,
  raw.output = TRUE
)

# Proposal to scenario -------------------------------------------------------
# scenario <- EpiModelHPC::swfcalib_proposal_to_scenario(proposal)
param_sc <- EpiModel::use_scenario(param, scenario)

param_sc$rgc.prob <- plogis(qlogis(param_sc$ugc.prob) + log(1.25))
param_sc$rct.prob <- plogis(qlogis(param_sc$uct.prob) + log(1.25))

# Simulation and processing --------------------------------------------------
sim <- netsim(est, param_sc, init, control)
dat <- sim[[1]]
# saveRDS(dat, "dat_test.rds")

at <- get_current_timestep(dat)

hivtest_msm <- function(dat, at) {

  ## Inputs
  # Attributes
  diag.status   <- get_attr(dat, "diag.status")
  race          <- get_attr(dat, "race")
  status        <- get_attr(dat, "status")
  inf.time      <- get_attr(dat, "inf.time")
  stage         <- get_attr(dat, "stage")
  late.tester   <- get_attr(dat, "late.tester")
  part.ident    <- get_attr(dat, "part.ident")
  entrTime      <- get_attr(dat, "entrTime")
  prepStat      <- get_attr(dat, "prepStat")
  last.neg.test <- get_attr(dat, "last.neg.test")
  diag.time     <- get_attr(dat, "diag.time")
  diag.stage    <- get_attr(dat, "diag.stage")

  # Parameters
  hiv.test.rate      <- get_param(dat, "hiv.test.rate")
  part.hiv.test.rate <- get_param(dat, "part.hiv.test.rate")
  vl.aids.int        <- get_param(dat, "vl.aids.int")
  test.window.int    <- get_param(dat, "test.window.int")
  prep.tst.int       <- get_param(dat, "prep.tst.int")

  aids.test.int      <- vl.aids.int / 2

  ## Process
  # Time since last negative test
  tsincelntst <- at - last.neg.test
  tsincelntst[is.na(tsincelntst)] <- at - entrTime[is.na(tsincelntst)]

  # Identified Partner Testing
  tstNeg.part <- numeric()
  tstPos.part <- numeric()
  eligPart <- which(part.ident == at & (diag.status == 0 | is.na(diag.status)))

  if (length(eligPart) > 0) {
    ## Testing: If any partners identified above, test randomly based on testing rate
    # Race of individuals identified for testing
    prob.screen <- part.hiv.test.rate[race[eligPart]]
    # Test screening
    screened <- eligPart[runif(length(eligPart)) < prob.screen]
    dat <- set_attr(dat, "part.scrnd", at, posit_ids = screened)
    # Testing results
    tstPos.part <- eligPart[status[screened] == 1]
    tstNeg.part <- eligPart[status[screened] == 0]
  }

  # General interval testing
  elig <- which((diag.status == 0 | is.na(diag.status)) &
                  prepStat == 0 & late.tester == 0)

  elig <- setdiff(elig, eligPart)

  # Interval testing rates by race
  rates <- hiv.test.rate[race[elig]]
  idsTstGen <- elig[runif(length(elig)) < rates]

  # Late testing (Neg, then AIDS)
  eligNeg <- which((diag.status == 0 | is.na(diag.status)) &
                     prepStat == 0 & status == 0 & late.tester == 1)

  eligNeg <- setdiff(eligNeg, eligPart)
  ratesNeg <- 1 / (12 * 52)
  idsTstLate <- eligNeg[runif(length(eligNeg)) < ratesNeg]

  eligAIDS <- which((diag.status == 0 | is.na(diag.status)) &
                      prepStat == 0 & stage == 4 & late.tester == 1)
  ratesAIDS <- 1 / aids.test.int
  idsTstAIDS <- eligAIDS[runif(length(eligAIDS)) < ratesAIDS]

  # PrEP testing
  idsTstPrEP <- which((diag.status == 0 | is.na(diag.status)) &
                        prepStat == 1 &
                        tsincelntst >= prep.tst.int)
  idsTstPrEP <- setdiff(idsTstPrEP, eligPart)

  tstAll <- c(idsTstGen, idsTstLate, idsTstAIDS, idsTstPrEP)

  tstPos <- tstAll[status[tstAll] == 1 & inf.time[tstAll] <= at - test.window.int]
  tstNeg <- setdiff(tstAll, tstPos)

  tstPos <- c(tstPos, tstPos.part)
  tstNeg <- c(tstNeg, tstNeg.part)
  tstAll <- c(tstAll, tstPos.part, tstNeg.part)

  # Update attributes
  last.neg.test[tstNeg] <- at
  diag.status[tstPos] <- 1
  diag.time[tstPos] <- at
  diag.stage[tstPos] <- stage[tstPos]

  ## Output
  # Set Attributes
  dat <- set_attr(dat, "last.neg.test", last.neg.test)
  dat <- set_attr(dat, "diag.status", diag.status)
  dat <- set_attr(dat, "diag.time", diag.time)
  dat <- set_attr(dat, "diag.stage", diag.stage)

  return(dat)
}
