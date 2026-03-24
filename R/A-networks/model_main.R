## Define and fit the *main* (long-term) network model
##
## This script should not be run directly. But `sourced` by `1-estimation.R`

# Formula — each term targets a specific network feature from ARTnet data.
# See the wiki for a reference of ERGM terms.
model_main <- ~ edges +
  nodematch("age.grp", diff = TRUE) +     # age homophily (separate by group)
  nodefactor("age.grp", levels = -1) +    # age group activity levels
  nodematch("race", diff = FALSE) +       # racial homophily (single parameter)
  nodefactor("race", levels = -1) +       # race activity levels
  nodefactor("deg.casl", levels = -1) +   # effect of casual degree on main
  concurrent +                            # count of nodes with 2+ partnerships
  degrange(from = 3) +                    # constrain max degree
  nodematch("role.class", diff = TRUE, levels = c(1, 2)) # sexual role homophily

# Target Stats — values from ARTnet that the fitting algorithm tries to match
netstats_main <- c(
  edges                = netstats$main$edges,
  nodematch_age.grp    = netstats$main$nodematch_age.grp,
  nodefactor_age.grp   = netstats$main$nodefactor_age.grp[-1],
  nodematch_race       = netstats$main$nodematch_race_diffF,
  nodefactor_race      = netstats$main$nodefactor_race[-1],
  nodefactor_deg.casl  = netstats$main$nodefactor_deg.casl[-1],
  concurrent           = netstats$main$concurrent,
  degrange             = 0,
  nodematch_role.class = c(0, 0)
) |> unname()

# Fit model
# - coef.diss: dissolution coefficients — control partnership duration
#   (age-dependent: older partnerships tend to last longer)
# - trim_netest(): removes network snapshots to save disk space; coefficients
#   are retained
fit_main <- EpiModel::netest(
  nw_main,
  formation = model_main,
  target.stats = netstats_main,
  coef.diss = netstats$main$diss.byage,
  set.control.ergm = control_ergm,
  verbose = FALSE
) |> EpiModel::trim_netest()

# Keep only the necessary objects
rm(model_main, netstats_main)
