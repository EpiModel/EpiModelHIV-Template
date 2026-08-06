make_restart_point_hiv <- function(sim, sim_num, sim_cost = Inf) {
  attrs_names <- names(EpiModelHIV::get_default_attrs())
  # ".due$" matters: EpiModelHIV >= 3.6.0 defines prep.inj.due as an absolute
  # timestep. Omitting it carries a step-3640 value into a run whose clock
  # restarts at 2, so injections never come due again, silently.
  time_prefixes <- c(".last$", ".time$", ".due$")

  time_attrs <- Reduce(
    function(a, prefix) c(a, grepv(prefix, attrs_names)),
    time_prefixes,
    init = character(0)
  )

  restart_point <- EpiModel::make_restart_point(
    sim,
    time_attrs,
    sim_num,
    keep_steps = 1
  )

  restart_point[["_calibration_cost"]] <- sim_cost
  restart_point
}
