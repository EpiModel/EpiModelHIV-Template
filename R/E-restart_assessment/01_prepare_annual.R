# =============================================================================
# 01_prepare_annual.R
# Question : What is in the 256 x 600-year dataset restarted from a single
#            state x0, and what annual dataset do the later steps work on?
# Inputs   : data/run/variance/df__variance_long.rds (weekly, long format)
# Outputs  : results/tables/01_*.csv, results/figures/01_*.png,
#            data/run/restart_assessment/01_annual.rds
# Method   : METHODS.md M1; results/01_prepare_annual.md
# =============================================================================

# Restart R before running this script (Ctrl_Shift_F10 / Cmd_Shift_0)

library(dplyr)
library(ggplot2)
theme_set(theme_light())
source("R/E-restart_assessment/00_config.R")
source("R/E-restart_assessment/utils.R")
set.seed(SEED)

# Load ------------------------------------------------------------------------
d <- readRDS(DATA_PATH)
cat("Class:", class(d), "\nDim:", dim(d), "\nSize:",
  format(object.size(d), units = "GB"), "\n")

d <- select(d, -batch_number, -sim_number) |> arrange(sim, time)
sims <- sort(unique(d$sim))
steps <- sort(unique(d$time))
stopifnot(
  length(steps) == N_YEARS * year_steps,
  all(table(d$sim) == length(steps))
)

# Restart state x0 --------------------------------------------------------------
# All chains share the restart state: the first recorded step must be identical
first_rows <- filter(d, time == min(steps)) |> select(-sim, -time)
x0_identical <- all(vapply(first_rows, function(x) length(unique(x)) == 1,
  logical(1)))
cat("First step identical across chains:", x0_identical, "\n")
x0_raw <- unlist(first_rows[1, ])

# Variable inventory ------------------------------------------------------------
# Kind is decided from EpiModelHIV semantics: `*.incid`, arrivals, departures
# and nNew are events per step (flows); everything else is a count at a time
# (stock).
raw_vars <- setdiff(names(d), c("sim", "time"))
flow_pattern <- "incid|^arrivals|^departures|^nNew$"
kind <- ifelse(grepl(flow_pattern, raw_vars), "flow", "stock")

# Exact duplicates and additive identities are checked on 8 chains
dd <- filter(d, sim %in% sims[1:8])
dup_of <- vapply(raw_vars, function(v) {
  others <- setdiff(raw_vars, v)
  hit <- others[vapply(others, function(o) identical(dd[[v]], dd[[o]]),
    logical(1))]
  if (length(hit)) paste(hit, collapse = ";") else ""
}, character(1))
sum_check <- function(tot) {
  parts <- paste0(tot, c(".B", ".H", ".W"))
  if (!all(parts %in% raw_vars)) return(NA)
  all(dd[[tot]] == dd[[parts[1]]] + dd[[parts[2]]] + dd[[parts[3]]])
}
is_race_total <- vapply(raw_vars, sum_check, logical(1))

inventory <- tibble(
  name = raw_vars,
  kind = kind,
  mean = vapply(d[raw_vars], mean, numeric(1)),
  min = vapply(d[raw_vars], min, numeric(1)),
  max = vapply(d[raw_vars], max, numeric(1)),
  n_na = vapply(d[raw_vars], function(x) sum(is.na(x)), numeric(1)),
  x0 = x0_raw[raw_vars],
  duplicate_of = dup_of,
  sum_of_race_groups = is_race_total
)
rm(dd)
write_tab(inventory, "01_raw_inventory.csv")

# Absorbing events: extinction of an STI in a chain ---------------------------
extinct <- d |>
  summarise(
    across(c(syph.inf, gono.inf, chla.inf, hiv.inf),
      ~ if (any(.x == 0)) (min(time[.x == 0]) - 2) / year_steps else NA_real_
    ),
    .by = sim
  ) |>
  filter(if_any(-sim, ~ !is.na(.x)))
write_tab(extinct, "01_extinctions_year.csv")
print(extinct)

# Annual aggregation ----------------------------------------------------------
# Year k covers steps (k - 1) * 52 + 2 ... k * 52 + 1. Rows are ordered by sim
# then time, so each column reshapes to [52, 600 * n_sims]: flows are summed
# over the year, stocks averaged (M1.2).
n_sim <- length(sims)
agg <- function(x, fun) {
  dim(x) <- c(year_steps, N_YEARS * n_sim)
  matrix(fun(x), N_YEARS, n_sim)
}
annual_raw <- setNames(lapply(seq_along(raw_vars), function(i) {
  f <- if (kind[i] == "flow") colSums else colMeans
  agg(d[[raw_vars[i]]], f)
}), raw_vars)
rm(d)
gc()

# Derived variables -------------------------------------------------------------
# Always ratios of annual aggregates, never means of weekly ratios (M1.3).
# Incidence rates are per 100 person-years at risk, with person-years
# approximated by the annual mean number of susceptible (HIV) or all (STI)
# individuals.
x0 <- as.list(x0_raw)
defs <- list()
for (g in c("", ".B", ".H", ".W")) {
  gg <- g
  v <- function(n) paste0(n, gg)
  defs[[paste0("prev", gg)]] <- local({
    a <- v("hiv.inf"); b <- v("num")
    list(rule = paste0(a, " / ", b),
      f = function(x) x[[a]] / x[[b]])
  })
  defs[[paste0("incid_rate", gg)]] <- local({
    a <- v("hiv.incid"); b <- v("num"); c <- v("hiv.inf")
    list(rule = paste0("100 * ", a, " / (", b, " - ", c, ")"),
      f = function(x) 100 * x[[a]] / (x[[b]] - x[[c]]), flow = TRUE)
  })
  defs[[paste0("dx_frac", gg)]] <- local({
    a <- v("hiv.dx"); b <- v("hiv.inf")
    list(rule = paste0(a, " / ", b), f = function(x) x[[a]] / x[[b]])
  })
  defs[[paste0("supp_frac", gg)]] <- local({
    a <- v("hiv.supp"); b <- v("hiv.inf")
    list(rule = paste0(a, " / ", b), f = function(x) x[[a]] / x[[b]])
  })
  defs[[paste0("prep_cov", gg)]] <- local({
    a <- v("prep"); b <- v("prep.indic")
    list(rule = paste0(a, " / ", b), f = function(x) x[[a]] / x[[b]])
  })
}
for (sti in c("gono", "chla", "syph")) {
  defs[[paste0(sti, "_prev")]] <- local({
    a <- paste0(sti, ".inf")
    list(rule = paste0(a, " / num"), f = function(x) x[[a]] / x[["num"]])
  })
  defs[[paste0(sti, "_ir")]] <- local({
    a <- paste0(sti, ".incid")
    list(rule = paste0("100 * ", a, " / num"),
      f = function(x) 100 * x[[a]] / x[["num"]], flow = TRUE)
  })
}

derived <- lapply(defs, function(def) def$f(annual_raw))
x0_derived <- vapply(names(defs), function(n) {
  # flows have no value at a single time point
  if (isTRUE(defs[[n]]$flow)) NA_real_ else defs[[n]]$f(x0)
}, numeric(1))

# Dictionary ------------------------------------------------------------------
# block: key = outputs the research reports; state = slow structural stocks
# (race-specific counts; totals are exact sums of these so they are left out
# to avoid redundancy); other = kept but not analysed.
state_vars <- c(
  as.vector(outer(
    c("num", "hiv.inf", "hiv.dx", "hiv.tx", "hiv.supp", "prep", "prep.indic"),
    c(".B", ".H", ".W"), paste0
  )),
  "gono.uret.inf", "gono.rect.inf", "chla.uret.inf", "chla.rect.inf",
  "syph.inf"
)
dict <- bind_rows(
  tibble(
    name = names(defs),
    kind = ifelse(vapply(defs, function(x) isTRUE(x$flow), logical(1)),
      "rate (flow / stock)", "proportion (stock / stock)"),
    annual_aggregation = vapply(defs, `[[`, character(1), "rule"),
    block = "key"
  ),
  tibble(
    name = "num", kind = "stock", annual_aggregation = "mean", block = "key"
  ),
  tibble(
    name = raw_vars,
    kind = kind,
    annual_aggregation = ifelse(kind == "flow", "sum", "mean"),
    block = ifelse(raw_vars %in% state_vars, "state", "other")
  ) |> filter(name != "num")
) |>
  mutate(
    analysis_scale = "raw",
    notes = case_when(
      name == "nNew" ~ "identical to arrivals",
      name %in% raw_vars[is_race_total %in% TRUE] ~ "sum of B/H/W",
      grepl("^syph", name) ~ "extinct in 2 chains (dropped)",
      TRUE ~ ""
    )
  )
write_tab(dict, "01_variable_dictionary.csv")

# Assemble and drop the chains with an absorbing extinction ---------------------
keep <- !(sims %in% DROP_SIMS)
Y <- c(derived, annual_raw)
Y <- lapply(Y, function(y) y[, keep, drop = FALSE])
annual <- list(
  Y = Y,
  x0 = c(x0_derived, x0_raw),
  sims = sims[keep],
  years = seq_len(N_YEARS),
  dict = dict
)
saveRDS(annual, ANNUAL_PATH)
cat("Annual object size:", format(object.size(annual), units = "MB"), "\n")

# Sanity figures ----------------------------------------------------------------
key_vars <- dict$name[dict$block == "key"]
show <- sample(ncol(Y[[1]]), 10)
long_band <- bind_rows(lapply(key_vars, function(v) {
  y <- Y[[v]]
  tibble(
    var = v, year = annual$years, mean = rowMeans(y),
    q05 = apply(y, 1, quantile, 0.05), q95 = apply(y, 1, quantile, 0.95)
  )
}))
long_chains <- bind_rows(lapply(key_vars, function(v) {
  tibble(
    var = v, year = rep(annual$years, 10),
    chain = rep(show, each = N_YEARS), value = as.vector(Y[[v]][, show])
  )
}))
x0_df <- tibble(var = key_vars, value = annual$x0[key_vars])

p <- ggplot(long_band, aes(year)) +
  geom_line(data = long_chains, aes(y = value, group = chain),
    alpha = 0.25, linewidth = 0.2) +
  geom_ribbon(aes(ymin = q05, ymax = q95), fill = "steelblue", alpha = 0.3) +
  geom_line(aes(y = mean), colour = "steelblue4") +
  geom_hline(data = x0_df, aes(yintercept = value), colour = "red",
    linetype = 2) +
  facet_wrap(~var, scales = "free_y", ncol = 4) +
  labs(x = "Years after restart", y = NULL,
    title = "Key variables: 10 chains, cross-chain mean and 5-95% band",
    subtitle = "Red dashed: value at the restart state x0")
save_fig(p, "01_key_600y.png", 14, 16)
save_fig(p + coord_cartesian(xlim = c(0, 100)), "01_key_first100y.png", 14, 16)

save_session("01")
