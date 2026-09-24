## Compute `tx.init.rate_{1,2,3}` from the `cc.linked1m.{B,H,W}` targets
##
## `cc.linked1m` = share of MSM diagnosed in 2024 linked to care (CD4, VL or
## genotype) within 30 days of diagnosis (NYC_calibration_targets.md, §2).
## `tx.init.rate` = weekly probability that a diagnosed, never-treated MSM
## starts treatment (EpiModelHIV `hivtx` module). Linkage is used as a proxy
## for treatment initiation.

library(EpiModelHIV)

# weekly probability giving a cumulative probability `p` within `i` weeks
i2r_p <- function(i, p) 1 - (1 - p)^(1 / i)

target_names <- paste0("cc.linked1m.", c("B", "H", "W"))
targets <- get_calibration_targets()[target_names]

interval <- 30 / 7 # 30 days, in weeks (time steps)
tx.init.rates <- vapply(targets, i2r_p, i = interval, 0.0)
names(tx.init.rates) <- paste0("tx.init.rate_", 1:3)
tx.init.rates
