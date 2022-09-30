load("dump.rda")
debugger(dump)

cea_msm <- function(dat, at) {

  # Function Selection ------------------------------------------------------
  if (at >= get_param(dat, "cea.start")) {
    if (at == get_param(dat, "end.horizon"))
      dat <- track_pop_msm(dat, at)

    dat <- track_cost_msm(dat, at)
    dat <- track_util_msm(dat, at)
  }

  return(dat)
}
