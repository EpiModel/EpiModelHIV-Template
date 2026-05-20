## 0. Generate the scenarios.csv file
##
## Programmatically define intervention scenarios and write them to
## "data/input/scenarios.csv".
##
## This example creates a 3x3 grid of scenarios varying HIV testing rates and
## treatment initiation rates at different odds ratios (0.25, 1, 4) relative to
## the calibrated baseline.

# Restart R before running this script

# Setup ----------------------------------------------------------------
library(EpiModelHIV)
library(dplyr)

source("R/shared_variables.R", local = TRUE)
source("R/D-interventions/z-context.R", local = TRUE)

# Process --------------------------------------------------------------

source("R/netsim_settings.R", local = TRUE)

# apply_or: shift a probability by an odds ratio.
# OR > 1 increases the probability, OR < 1 decreases it.
# OR = 1 leaves it unchanged (baseline).
apply_or <- function(p, or) plogis(qlogis(p) + log(or))

# Odds ratios to test: 1/4 (decrease), 1 (baseline), 4 (increase)
ors <- c(lo = 1 / 4, base = 1, hi = 4)

sc_list <- list()

for (or_test in ors) {
  for (or_tx in ors) {
    sc_name <- paste0(
      "test_", or_test, "_treat_", or_tx
    )
    sc_list[[sc_name]] <- tibble(
      .scenario.id    = sc_name,
      .at             = intervention_start,
      hiv.test.rate_1 = apply_or(
        param$hiv.test.rate[[1]], or_test
      ),
      hiv.test.rate_2 = apply_or(
        param$hiv.test.rate[[2]], or_test
      ),
      hiv.test.rate_3 = apply_or(
        param$hiv.test.rate[[2]], or_test
      ),
      tx.init.rate_1  = apply_or(
        param$tx.init.rate[[1]], or_tx
      ),
      tx.init.rate_2  = apply_or(
        param$tx.init.rate[[2]], or_tx
      ),
      tx.init.rate_3  = apply_or(
        param$tx.init.rate[[3]], or_tx
      )
    )
  }
}

sc_df <- bind_rows(sc_list)
write.csv(sc_df, "data/input/scenarios.csv", row.names = FALSE)
