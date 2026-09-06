library(hetGP)
library(MASS)
library(dplyr)
library(ggplot2)
theme_set(theme_light())
source("./R/C-calibration/z-gp_utils.R", local = TRUE)
results <- readRDS("./gp_res.rds")
d <- filter(results, .iteration == 1)

# d <- d1
disease <- c("syph", "gono", "chla")[2]
mod_choice <- c("hom", "het")[2]
# Choice of inputs -------------------------------------------------------------
if (disease == "syph") {
  par_raw <- d$syph.prob
  val <- d$ir100.syph
  tar <- 2
} else if (disease == "gono") {
  par_raw <- d$gono.uret.prob
  val <- d$ir100.gono
  tar <- 12.810
} else if (disease == "chla") {
  par_raw <- d$chla.uret.prob
  val <- d$ir100.chla
  tar <- 14.59
}

if (between(tar, min(val), max(val))) {
  par_range <- range(par_raw)
} else {
  par_range <- c(0.05, 0.3)
}


ggplot(tibble(x = par_raw, y = val), aes(x = x, y = y)) +
  geom_jitter()

# Models -----------------------------------------------------------------------
par <- mscale(par_raw, par_range)
mod <- mleHetGP(par, val, covtype = "Matern5_2", eps = 1e-6)

f_mean <- function(x) predict(mod, matrix(x, ncol = 1))$mean - tar
# search over the scaled domain; assumes a single crossing (fine for monotone)
root <- uniroot(f_mean, interval = c(0, 1))
par_star <- munscale(root$root, par_range)

# Plotting ---------------------------------------------------------------------
plot_gp(mod, val, par_range, tar)

# Make a batch with crit_cSUR --------------------------------------------------

new_p <- get_new_gp_prop(mod, length(par_raw), target = tar)
np <- munscale(new_p, par_range)
sort(np)

filter(results, .iteration == 2) |> pull(syph.prob) |> sort()
filter(results, .iteration == 2) |> pull(gono.uret.prob) |> sort()
filter(results, .iteration == 2) |> pull(chla.uret.prob) |> sort()


saveRDS(np, paste0(disease, "-props.rds"))

tol_y <- 0.25
grid01 <- seq(0, 1, length.out = 1e3)
ci <- contour_ci(mod, thres = tar, grid01, probs = c(0.05, 0.95))
sub <- grid01[grid01 >= ci[1] & grid01 <= ci[2]]
if (length(sub) < 2) sub <- ci[1:2]            # CI narrower than grid step
y_span  <- predict(mod, matrix(sub, ncol = 1))$mean
y_width <- diff(range(y_span))
fcross <- ci["frac_crossing"]
(converged <- (y_width < tol_y) && (fcross > 0.95))
