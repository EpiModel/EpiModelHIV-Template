pkgload::load_all("../../core_EM/EpiModel/")
library(dplyr)
library(EpiModelHIV)
source("R/shared_variables.R", local = TRUE)
source("R/B-model_dev/z-context.R")
source("R/netsim_settings.R", local = TRUE)
control <- control_msm(
  nsteps = year_steps / 4,
  tracked.attributes = c('hiv.dx', 'gono.uret'),
  # tracked.attributes = c("active", "hiv.vl"),
  cumulative.edgelist = TRUE,
  truncate.el.cuml = Inf,
  save.cumulative.edgelist = TRUE
)
est <- readRDS(path_to_est)
sim <- netsim(est, param, init, control)


# To network dynamic -----------------------------------------------------------
n_nodes <- max(sim$run$sim1$attr$unique_id)
n_steps <- control$nsteps

nw <- network.initialize(n_nodes, directed = FALSE)
el <- sim$cumulative.edgelist$sim1 |>
  mutate(stop = ifelse(is.na(stop), sim$run$sim1$current_timestep, stop))

add.edges.active(
  nw,
  head = el$head,
  tail = el$tail,
  onset = el$start,
  terminus = el$stop + 1L,
  names.eval = rep(list("network"), nrow(el)),
  vals.eval = lapply(el$network, \(x) list(network = x))
)

for (at in seq_along(sim$run$sim1$tracked_attributes)) {
  for (item in names(sim$run$sim1$tracked_attributes[[at]])) {
    if (item == "active") {
      on_pos <- which(sim$run$sim1$tracked_attributes[[at]][[item]]$value == 1)
      off_pos <- which(sim$run$sim1$tracked_attributes[[at]][[item]]$value == 0)
      uids <- sim$run$sim1$tracked_attributes[[at]][[item]]$uid[on_pos]
      activate.vertices(nw, v = uids, onset = at, terminus = Inf)
      uids <- sim$run$sim1$tracked_attributes[[at]][[item]]$uid[off_pos]
      deactivate.vertices(nw, v = uids, onset = at, terminus = Inf)
    }
    uids <- sim$run$sim1$tracked_attributes[[at]][[item]]$uid
    values <- sim$run$sim1$tracked_attributes[[at]][[item]]$value
    activate.vertex.attribute(
      nw,
      item,
      v = uids,
      value = values,
      onset = at,
      terminus = Inf
    )
  }
}

is.active(nw, at = 13, v = 10046)

# NOTE: change format to UID-ATTRS-onset/value
#
# elt <- list(onset = integer(0), value = numeric(0))
# tracked_attrs <- lapply(control$tracked.attributes, \(x) elt)
# names(tracked_attrs) <- control$tracked.attributes
# attrs <- lapply(seq_len(n_nodes), \(x) tracked_attrs)
# for (ta in control$tracked.attributes) {
#   for (ts in seq_along(sim$run$sim1$tracked_attributes)) {
#     elt <- sim$run$sim1$tracked_attributes[[ts]][[ta]]
#     uids <- elt$uid
#     values <- elt$value
#     for (i in seq_along(uids)) {
#       uid <- uids[i]
#       attrs[[uid]][[ta]]$onset <- c(attrs[[uid]][[ta]]$onset, ts)
#       attrs[[uid]][[ta]]$value <- c(attrs[[uid]][[ta]]$value, values[i])
#     }
#   }
# }

# With TergmLite ---------------------------------------------------------------
pkgload::load_all("../../core_EM/EpiModel/")
library(dplyr)
library(ndtv)
set.seed(1)

# 1. Network setup + TERGM estimation
n <- 1e3
nw <- network_initialize(n = n)
formation <- ~edges
target.stats <- 0.4 * n
coef.diss <- dissolution_coefs(dissolution = ~ offset(edges), duration = 10)
est <- netest(nw, formation, target.stats, coef.diss)

# 2. Epidemic simulation
param <- param.net(inf.prob = 1)
init <- init.net(i.num = 0.1 * n)
control <- control.net(
  type = "SI",
  nsteps = 100,
  nsims = 1,
  tergmLite = TRUE,
  tracked.attributes = c('status'),
  cumulative.edgelist = TRUE,
  truncate.el.cuml = Inf,
  save.cumulative.edgelist = TRUE,
  save.run = TRUE,
  verbose = FALSE
)
system.time({
  sim <- netsim(est, param, init, control)
})

# To network dynamic -----------------------------------------------------------
n_nodes <- max(sim$run$sim1$attr$unique_id)
n_steps <- control$nsteps

nw <- network.initialize(n_nodes, directed = FALSE)
el <- sim$cumulative.edgelist$sim1 |>
  mutate(stop = ifelse(is.na(stop), sim$run$sim1$current_timestep, stop))

add.edges.active(
  nw,
  head = el$head,
  tail = el$tail,
  onset = el$start,
  terminus = el$stop + 1L,
  names.eval = rep(list("network"), nrow(el)),
  vals.eval = lapply(el$network, \(x) list(network = x))
)

for (at in seq_along(sim$run$sim1$tracked_attributes)) {
  for (item in names(sim$run$sim1$tracked_attributes[[at]])) {
    if (item == "active") {
      on_pos <- which(sim$run$sim1$tracked_attributes[[at]][[item]]$value == 1)
      off_pos <- which(sim$run$sim1$tracked_attributes[[at]][[item]]$value == 0)
      uids <- sim$run$sim1$tracked_attributes[[at]][[item]]$uid[on_pos]
      activate.vertices(nw, v = uids, onset = at, terminus = Inf)
      uids <- sim$run$sim1$tracked_attributes[[at]][[item]]$uid[off_pos]
      deactivate.vertices(nw, v = uids, onset = at, terminus = Inf)
    } else {
      uids <- sim$run$sim1$tracked_attributes[[at]][[item]]$uid
      values <- sim$run$sim1$tracked_attributes[[at]][[item]]$value
      activate.vertex.attribute(
        nw,
        item,
        v = uids,
        value = values,
        onset = at,
        terminus = Inf
      )
    }
  }
}

orig_nw <- get_network(sim)

# 3. Extract networkDynamic + color by infection status
nw <- color_tea(nw, old.var = "status", verbose = FALSE)
orig_nw <- color_tea(orig_nw, verbose = FALSE)

# 4. Compute layout + render
slice.par <- list(
  start = 1,
  end = 25,
  interval = 1,
  aggregate.dur = 1,
  rule = "any"
)
compute.animation(nw, slice.par = slice.par)
render.d3movie(
  nw,
  vertex.cex = 0.9,
  vertex.col = "ndtvcol",
  edge.col = "darkgrey",
  vertex.border = "lightgrey",
  displaylabels = FALSE,
  filename = paste0(getwd(), "/movie.html")
)

compute.animation(orig_nw, slice.par = slice.par)
render.d3movie(
  orig_nw,
  vertex.cex = 0.9,
  vertex.col = "ndtvcol",
  edge.col = "darkgrey",
  vertex.border = "lightgrey",
  displaylabels = FALSE,
  filename = paste0(getwd(), "/movie.html")
)
