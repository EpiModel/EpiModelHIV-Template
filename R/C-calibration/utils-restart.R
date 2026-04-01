make_restart_point_hiv <- function(sim, sim_num, sim_cost = Inf) {
  attrs_names <- names(EpiModelHIV::get_default_attrs())
  time_prefixes <- c(".last$", ".time$")

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
